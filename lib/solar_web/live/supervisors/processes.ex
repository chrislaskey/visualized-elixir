defmodule SolarWeb.SupervisorsLive.Processes do
  @root_process_name :"SolarWeb.SupervisorsLive.Supervisor"

  def root_process_name, do: @root_process_name

  def update(data) do
    all_prev_configs = SolarWeb.SupervisorsLive.Agent.Processes.get()
    parse_and_store_child_processes(data)
    all_next_configs = SolarWeb.SupervisorsLive.Agent.Processes.get()

    update_changed_processes(all_prev_configs, all_next_configs)
  end

  def parse_and_store_child_processes(data) do
    data
    |> parse_child_processes_by_parent()
    |> store_child_processes_by_parent_in_agent()
  end

  def restart_all_processes() do
    Supervisor.terminate_child(Solar.Supervisor, root_process_name())
    Supervisor.restart_child(Solar.Supervisor, root_process_name())
  end

  def terminate_and_delete_process(parent, name) do
    if Process.whereis(name) do
      # `terminate_child` stops the running process. The process' child spec is kept in the supervisor.
      # This is useful when you may restart a process later using `restart_child`. But in our case we
      # want to remove the spec, since it contains information like `strategy` that might be different the
      # next time it's recreated. So we also have to `delete_child` which removes the child spec.
      Supervisor.terminate_child(parent, name)
      Supervisor.delete_child(parent, name)
    end
  end

  def start_process(parent, name) do
    if Process.whereis(name) == nil do
      Supervisor.start_child(parent, name)
    end
  end

  def restart_process(parent, name) do
    terminate_and_delete_process(parent, name)
    start_process(parent, name)
  end

  # Helpers

  defp parse_child_processes_by_parent(data) do
    nodes = Map.get(data, "nodes", [])
    edges = Map.get(data, "edges", [])
    edges_lookup = Map.new(edges, fn edge -> {edge["target"], edge["source"]} end)

    Enum.reduce(nodes, %{}, fn process_data, acc ->
      process_name = Map.get(process_data, "id")
      parent_name = Map.get(edges_lookup, process_name, "SolarWeb.SupervisorsLive.Supervisor")
      process_options = parse_child_process_options(process_name, process_data)

      Map.update(acc, parent_name, %{process_name => process_options}, fn existing ->
        Map.put(existing, process_name, process_options)
      end)
    end)
  end

  defp parse_child_process_options(process_name, process_data) do
    flattened_map =
      process_data["data"]
      |> Map.merge(Map.get(process_data["data"], "config", %{}))
      |> Map.merge(process_data)
      |> Map.delete("data")
      |> Map.delete("config")

    as_keyword_list =
      flattened_map
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
      |> Enum.into([])

    with_new_keys = Keyword.put(as_keyword_list, :name, String.to_atom(process_name))

    with_atom_values =
      Keyword.replace_lazy(with_new_keys, :strategy, fn value -> String.to_atom(value) end)

    with_atom_values
  end

  defp store_child_processes_by_parent_in_agent(processes_by_parent) do
    process_type_to_module_lookup = %{
      "supervisor" => SolarWeb.SupervisorsLive.Supervisor,
      "genserver" => SolarWeb.SupervisorsLive.Supervisor,
      "producer" => SolarWeb.SupervisorsLive.Supervisor,
      "consumer" => SolarWeb.SupervisorsLive.Supervisor
    }

    :ok = SolarWeb.SupervisorsLive.Agent.Processes.clear_all()

    Enum.map(processes_by_parent, fn {key, value} ->
      name = String.to_atom(key)

      children =
        Enum.map(value, fn {_, child} ->
          child_module = Map.get(process_type_to_module_lookup, child[:type])
          child_options = child

          {child_module, child_options}
        end)

      SolarWeb.SupervisorsLive.Agent.Processes.set_children(name, children)
    end)

    :ok
  end

  def update_changed_processes(all_prev_configs, all_next_configs) do
    root_name = @root_process_name
    root_process = Process.whereis(root_name)
    root_next_config = Map.get(all_next_configs, root_name)
    root_children_names = get_combined_children_names(root_next_config, root_process, root_name)

    for child_name <- root_children_names do
      walk_structure(all_prev_configs, all_next_configs, root_name, child_name)
    end
  end

  defp walk_structure(all_prev_configs, all_next_configs, parent_name, name) do
    prev_config = Map.get(all_prev_configs, name)
    next_config = get_next_config(all_next_configs, parent_name, name)
    current_process = Process.whereis(name)
    children_names = get_combined_children_names(next_config, current_process, name)

    cond do
      #
      # Currently running but not in next config
      next_config == nil && current_process ->
        dbg(terminate_and_delete_process(parent_name, name))

      #
      # Not current running but in next config
      next_config && current_process == nil ->
        dbg(start_process(parent_name, name))

      #
      # Currently running and in next config but different previous config
      process_configs_different?(prev_config, next_config) ->
        dbg(restart_process(parent_name, name))

      #
      # Currently running and in next config and same previous config
      Enum.any?(children_names) ->
        dbg(walk_structure_for_children(all_prev_configs, all_next_configs, name, children_names))

      #
      # End of a node in a tree
      :else ->
        :ok
    end
  end

  defp get_next_config(all_next_configs, parent_name, name) do
    # The `prev_config` has all the information under one key. But until the processes
    # are actually created, the `next_config` only has the parent -> children
    # relationships. So in this case, we lookup both and merge them together.
    #
    # Returns `nil` when not found to mirror the `Map.get()` behaviour
    parent_config =
      if Map.has_key?(all_next_configs, parent_name) do
        all_next_configs
        |> Map.get(parent_name)
        |> Keyword.get(:children, [])
        |> Enum.find_value(fn entry ->
          options = elem(entry, 1)

          if Keyword.get(options, :name) == name, do: options, else: false
        end)
        |> Kernel.||([])
      else
        []
      end

    process_config = 
      if Map.has_key?(all_next_configs, name) do
        Map.get(all_next_configs, name)
      else
        []
      end

    combined_config = Keyword.merge(parent_config, process_config)

    if Enum.any?(combined_config) do
      combined_config
    else
      nil
    end
  end

  defp process_configs_different?(nil, _next_config), do: true
  defp process_configs_different?(_prev_config, nil), do: true

  defp process_configs_different?(prev_config, next_config) do
    prev = Keyword.drop(prev_config, [:label, :position, :id, :children]) |> Enum.sort()
    next = Keyword.drop(next_config, [:label, :position, :id, :children]) |> Enum.sort()

    prev != next
  end

  defp walk_structure_for_children(all_prev_configs, all_next_configs, name, children_names) do
    for child_name <- children_names do
      walk_structure(all_prev_configs, all_next_configs, name, child_name)
    end
  end

  defp get_combined_children_names(next_config, current_process, name) do
    current_children_names = get_current_children_names(name, current_process)
    next_children_names = get_next_config_children_names(next_config)

    next_children_names
    |> Kernel.++(current_children_names)
    |> Enum.uniq()
  end

  defp get_current_children_names(_name, nil), do: []

  defp get_current_children_names(name, _process) do
    name
    |> SolarWeb.SupervisorsLive.Supervisor.which_children()
    |> Enum.map(fn entry -> elem(entry, 0) end)
  end

  def get_next_config_children_names(nil), do: []

  def get_next_config_children_names(next_config) do
    next_config
    |> Keyword.get(:children, [])
    |> Enum.map(fn item ->
      item
      |> elem(1)
      |> Keyword.get(:name)
    end)
  end
end
