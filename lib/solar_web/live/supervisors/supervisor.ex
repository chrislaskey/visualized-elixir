defmodule SolarWeb.SupervisorsLive.Supervisor do
  use Supervisor

  @root_process_name :"SolarWeb.SupervisorsLive.Supervisor"
  @child_definition {SolarWeb.SupervisorsLive.Supervisor,
                     name: @root_process_name,
                     strategy: :one_for_one,
                     type: "supervisor",
                     max_restarts: 10_000,
                     max_seconds: 5}

  @orphan_timeout 5_000

  def child_definition, do: @child_definition
  def root_process_name, do: @root_process_name

  # Children

  def start_child(supervisor, child) do
    Supervisor.start_child(supervisor, child)
  end

  def count_children(supervisor) do
    Supervisor.count_children(supervisor)
  end

  def which_children(supervisor) do
    Supervisor.which_children(supervisor)
  end

  def terminate_child(supervisor, pid) do
    Supervisor.terminate_child(supervisor, pid)
  end

  def restart_child(supervisor, pid) do
    Supervisor.restart_child(supervisor, pid)
  end

  # Supervisor

  def child_spec(opts \\ []) do
    # Supervisor uses the `id` to prevent duplicates. By default
    # the built-in child_spec function sets the ID to the module name.
    # This prevents us from creating multiple Supervisor children with
    # the same ID. The fix is to define our own `child_spec` function and
    # set the `id` to the `name` value instead.
    #
    # Note that `max_restarts` and `max_seconds` are not child spec keys. They
    # belong to the supervisor doing the restarting, so they are read in
    # `init/1` below. Unknown keys in a child spec map are silently ignored.
    name = Keyword.fetch!(opts, :name)
    restart = Keyword.get(opts, :restart, :permanent)

    %{
      id: name,
      restart: restart,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    name = Keyword.fetch!(opts, :name)

    handle_potential_orphans(fn ->
      Supervisor.start_link(__MODULE__, opts, name: name)
    end)
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    init_options = Keyword.take(opts, [:strategy, :max_restarts, :max_seconds])

    children = SolarWeb.SupervisorsLive.Agent.Processes.get_children(name)
    process = Keyword.put(opts, :children, children)

    SolarWeb.SupervisorsLive.Agent.Processes.merge(name, process)
    SolarWeb.SupervisorsLive.Presence.track_pid(self(), name, presence(%{status: "starting"}))
    SolarWeb.SupervisorsLive.Presence.update_pid(self(), name, presence(%{status: "running"}), after: 500)

    Supervisor.init(children, init_options)
  end

  def presence(additional \\ %{}) do
    base = %{pid: inspect(self())}

    Map.merge(base, additional)
  end

  # Helpers

  defp handle_potential_orphans(start_link_call) do
    # NOTE: The key logic for orphan handling generated with the help of LLMs.
    # The brutal-kill edge-case proved tricky to detect and debug. The solution
    # it generated makes sense!
    case start_link_call.() do
      {:error, {:already_started, pid}} = error -> handle_orphans(pid, error, start_link_call)
      response -> response
    end
  end

  defp handle_orphans(pid, error, start_link_call) do
    # A brutal kill (`:kill`) on a supervisor kills it instantly, without
    # giving it a chance to shut down its children. Its parent restarts it
    # right away, and the new process tries to start children under the
    # same names. But the old children are still alive: they got the exit
    # signal from their dead parent and are busy shutting themselves down,
    # and their registered names stay taken until they finish. So the
    # restart fails with `:already_started`, and because OTP retries
    # failed restarts immediately with no backoff, the parent burns through
    # its restart intensity in microseconds.
    #
    # If the process holding the name is such an orphan, it is guaranteed
    # to exit soon, so wait for it and try again. If it is not an orphan,
    # this is a genuine duplicate and the error stands.
    if orphan?(pid) and await_exit(pid, @orphan_timeout) == :ok do
      start_link_call.()
    else
      error
    end
  end

  # A process whose parent (the process that spawned it) is dead. For an OTP
  # process started by a supervisor, that means its supervisor is gone and it
  # is in the middle of exiting. `Process.info(pid, :parent)` needs OTP 25+.
  defp orphan?(pid) do
    case Process.info(pid, :parent) do
      {:parent, parent} when is_pid(parent) -> not Process.alive?(parent)
      _ -> false
    end
  end

  defp await_exit(pid, timeout) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        :timeout
    end
  end
end
