class Slate::Doc
  attr_reader :root

  def self.parse(document)
    parsed = document.is_a?(Hash) ? document : JSON.parse(document)
    self.new(parsed)
  end

  def initialize(data)
    @root = data
  end

  def visit(node = @root, &visitor)
    visit_node(node, visitor)
  end

  def visit_node(node, visitor)
    descend = visitor.call(node)
    if node["nodes"] and descend != false
      node["nodes"].each do |child|
        visit_node(child, visitor)
      end
    end
  end
end
