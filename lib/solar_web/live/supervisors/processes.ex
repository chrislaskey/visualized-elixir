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

  def terminate_process(parent, name) do
    if Process.whereis(name) do
      Supervisor.terminate_child(parent, name)
    end
  end

  def start_process(parent, name) do
    if Process.whereis(name) do
      Supervisor.restart_child(parent, name)
    end
  end

  def restart_process(parent, name) do
    terminate_process(parent, name)
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
    parent_name = Solar.Supervisor
    name = @root_process_name

    walk_structure(all_prev_configs, all_next_configs, parent_name, name)
  end

  defp walk_structure(all_prev_configs, all_next_configs, parent_name, name) do
    prev_config = Map.get(all_prev_configs, name)
    next_config = Map.get(all_next_configs, name)

    current_process = Process.whereis(name)
    children_names = get_combined_children_names(next_config, current_process, name)

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
