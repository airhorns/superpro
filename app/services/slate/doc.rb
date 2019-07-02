class Slate::Doc
  def initialize(data)
    @data = data
  end

  def visit(&visitor)
    visit_node(@data, visitor)
  end

  def visit_node(node, visitor)
    visitor.call(node)
    if node["nodes"]
      node["nodes"].each do |child|
        visit_node(child, visitor)
      end
    end
  end
end
