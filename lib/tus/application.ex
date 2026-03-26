defmodule Tus.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Tus.Supervisor]
    Supervisor.start_link(get_children(), opts)
  end

  defp get_children do
    Application.get_env(:tus, :controllers, [])
    |> Enum.map(&get_child_spec/1)
  end

  defp get_child_spec(controller) do
    config =
      Application.get_env(:tus, controller)
      |> Enum.into(%{})
      |> Map.put(:cache_name, Module.concat(controller, TusCache))

    {config.cache, config}
  end
end
