# frozen_string_literal: true
# rubocop:disable Naming/MethodName

class DataModel::HasAggregationsNodeVisitor < Arel::Visitors::Visitor
  def visit_aggregate_function(_node)
    true
  end

  alias visit_Arel_Nodes_Avg visit_aggregate_function
  alias visit_Arel_Nodes_Sum visit_aggregate_function
  alias visit_Arel_Nodes_Count visit_aggregate_function
  alias visit_Arel_Nodes_Max visit_aggregate_function
  alias visit_Arel_Nodes_Min visit_aggregate_function

  def visit_Arel_Nodes_NamedFunction(node)
    node.expressions.any? { |child| visit(child) }
  end

  def visit_Arel_Nodes_InfixOperation(node)
    visit(node.left) || visit(node.right)
  end

  def visit_Arel_Nodes_Binary(node)
    visit(node.left) || visit(node.right)
  end

  def visit_Arel_Nodes_SqlLiteral(node)
    node.to_s.start_with?("percentile_cont")
  end

  def visit_Arel_Nodes_Grouping(node)
    visit node.expr
  end

  def visit_Arel_Nodes_And(node)
    node.children.any? { |child| visit(child) }
  end

  def visit_Arel_Nodes_Or(node)
    visit(node.left) || visit(node.right)
  end

  def visit_Arel_Nodes_Casted(node)
    visit(node.val) || visit(node.attribute)
  end

  def visit_scalar(_node)
    false
  end

  alias visit_Integer visit_scalar
  alias visit_String visit_scalar
  alias visit_Arel_Nodes_Quoted visit_scalar
  alias visit_Arel_Attributes_Attribute visit_scalar
end

# rubocop:enable Naming/MethodName
