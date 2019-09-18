# frozen_string_literal: true

require "shellwords"
require "securerandom"

class Infrastructure::KubernetesClient
  include SemanticLogger::Loggable

  def self.client
    @client ||= self.new
  end

  attr_reader :client

  def initialize
    @rails_pod_template_data = Rails.configuration.kubernetes.pod_template_data

    @client = if Rails.configuration.kubernetes.key?(:kube_config)
                K8s::Client.config(K8s::Config.load_file(File.expand_path(Rails.configuration.kubernetes.kube_config)))
              elsif Rails.configuration.kubernetes.key?(:in_cluster_config) && Rails.configuration.kubernetes.in_cluster_config
                K8s::Client.in_cluster_config
              else
                raise "No configuration options for ruby kubernetes client specified. Please add a kube_config location or specify in_cluster_config: true"
              end
  end

  def run_background_job_in_k8s(job_class, args)
    class_name = job_class.name

    if job_class.ancestors.include?(Que::Job) && job_class.exclusive_execution_lock && !job_class.lock_available?(args)
      logger.info("Skipped k8s job enqueue as the lock is unavailable right now", job_class: job_class, args: args)
      return
    end

    create_long_running_rails_job(
      "zzjob-#{class_name.gsub(/[^A-Za-z0-9]/, "-").downcase}-#{SecureRandom.hex(5)}",
      ["bundle", "exec", "rake", "job:run_inline[#{Shellwords.escape(class_name)}, #{Shellwords.escape(args.to_json)}]"]
    )
  end

  def create_long_running_rails_job(name, command)
    job = K8s::Resource.new(
      apiVersion: "batch/v1",
      kind: "Job",
      metadata: {
        name: name,
        namespace: Rails.configuration.kubernetes.namespace,
      },
      spec: {
        completions: 1,
        parallelism: 1,
        backoffLimit: 0,
        ttlSecondsAfterFinished: 7.days.to_i,
        template: {
          metadata: {
            name: name,
          },
          spec: {
            containers: [
              {
                name: "execute-job",
                image: Rails.configuration.kubernetes.rails_image,
                command: command,
                env: @rails_pod_template_data[:rails_environment],
                volumeMounts: @rails_pod_template_data[:rails_volume_mounts],
                securityContext: { capabilities: { add: ["SYS_PTRACE"] } },
              },
            ],
            volumes: @rails_pod_template_data[:rails_volumes],
            restartPolicy: "Never",
          },
        },
      },
    )

    @client.api("batch/v1").resource("jobs", namespace: Rails.configuration.kubernetes.namespace).create_resource(job)
  end
end
