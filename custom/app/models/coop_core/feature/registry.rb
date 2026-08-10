# Code-declared catalogue of CoopFlow modules (design §5.1), loaded once per
# boot from custom/config/coop_modules.yml and memoized. Adding a module is a
# PR; enabling one is a config change (CoopCore::ModuleDefault /
# CoopCore::ModuleSetting) with no deploy.
class CoopCore::Feature::Registry
  Definition = Struct.new(:key, :name, :description, :default_enabled, :licensable, :depends_on) do
    def default_enabled?
      !!default_enabled
    end
  end

  CONFIG_PATH = Rails.root.join('custom/config/coop_modules.yml')

  class << self
    def modules
      @modules ||= load_modules
    end

    def keys
      modules.map(&:key)
    end

    def find(key)
      modules_by_key.fetch(key.to_s) { raise ::CoopCore::Feature::UnknownModuleError, "unknown module: #{key}" }
    end

    private

    def modules_by_key
      @modules_by_key ||= modules.index_by(&:key)
    end

    def load_modules
      raw = YAML.load_file(CONFIG_PATH)
      definitions = raw.map { |entry| build_definition(entry) }
      assert_no_cycles!(definitions)
      definitions
    end

    def build_definition(entry)
      Definition.new(
        entry.fetch('key'),
        entry['name'],
        entry['description'],
        entry.fetch('default_enabled', false),
        entry.fetch('licensable', false),
        entry.fetch('depends_on', [])
      )
    end

    # Cheap DFS cycle guard, run once at load time -- a cyclic depends_on
    # would otherwise cause CoopCore::Feature::Resolver#resolve to recurse
    # forever the first time it is exercised.
    def assert_no_cycles!(definitions)
      graph = definitions.to_h { |definition| [definition.key, definition.depends_on] }
      graph.each_key { |key| visit(key, graph, []) }
    end

    def visit(key, graph, stack)
      raise ::CoopCore::Feature::CyclicDependencyError, cycle_message(stack, key) if stack.include?(key)

      (graph[key] || []).each { |dependency| visit(dependency, graph, stack + [key]) }
    end

    def cycle_message(stack, key)
      "cyclic module dependency: #{(stack + [key]).join(' -> ')}"
    end
  end
end
