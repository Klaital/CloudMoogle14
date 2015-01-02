# craft_requirements_calculator.rb

require 'json'

class CraftRequirementsCalculator
    def initialize(opts={})
        items_path = opts[:items_path] || File.join(__dir__, '..', 'config', 'items.json')
        recipes_path = opts[:recipes_path] || File.join(__dir__, '..', 'config', 'recipes.json')
        reagents_path = opts[:reagents_path] || File.join(__dir__, '..', 'config', 'reagents.json')
        @recipes = opts[:recipes] || JSON.load(File.read(recipes_path))
        @items = opts[:items] || JSON.load(File.read(items_path))
    end

    def get_item_ingredients(item_name)
        @recipes.each do |recipe|
            return recipe['ingredients'] if recipe['name'] == item_name
        end

        return []
    end

    # Generate a list of all items needed from all sources to craft everything from scratch
    def decompose_item(item_name, qty=1)
#        puts "> Decomposing #{item_name} x#{qty}"
        # Find the ingredients for the workpiece
        ingredients = get_item_ingredients(item_name)

        if ingredients.nil? || ingredients.empty?
            return { item_name => {'qty'=>qty}}
        end

        # Recurse to find all of its ingredients
        final_ingredients = {}
        ingredients.each do |ingredient|
            decomposition = decompose_item(ingredient['name'], ingredient['required'].to_i)

            
            if decomposition.keys.length == 1 && decomposition.keys.include?(ingredient['name'])
                # If the item cannot be broken down further, then we're done
#                puts ">> Leaf node found: #{ingredient['name']} x#{ingredient['required']}"
                final_ingredients[ingredient['name']] = {'qty' => 0} unless final_ingredients.has_key?(ingredient['name'])
                final_ingredients[ingredient['name']]['qty'] += ingredient['required'].to_i
            else
                # Merge the new ingredients
                decomposition.each_pair do |name, data|
                    final_ingredients[name] = {'qty' => 0} unless final_ingredients.has_key?(name)
                    final_ingredients[name]['qty'] += data['qty']
                end
            end


        end


        final_ingredients
    end

end


if __FILE__ == $0

    require 'optparse'

    item_name = nil
    quantity  = 1
    OptionParser.new do |opts|
        opts.banner = "Tool for deciding how much of each thing you need to craft an end result"
        opts.on('-i', '--item NAME', 'Item name to be crafted') do |name|
            item_name = name
        end
        opts.on('-q', '--quantity INT', 'How many of that item you want to end up with.') do |qty|
            quantity = qty.to_i
        end

        opts.on_tail('-h', '--help', 'Display this help text') do
            puts opts.to_s
            exit(0)
        end
    end.parse!

    
    calc = CraftRequirementsCalculator.new

    ingredients = calc.decompose_item(item_name, quantity)
    puts JSON.pretty_generate(ingredients)
end
