defmodule MetricsHelper do
  @moduledoc """
  Metrics-gathering functions
  """

  def bucket(n, unit),
    do: div(n, unit) * unit
end
