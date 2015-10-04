defmodule Dogma.Rule.VariableNameLength do
  @moduledoc """
  A rule that disallows variable names which are only one character long.

  It does permit `i`, as a traditional name for counters, as well as `_`.

  Good:
      my_mood = :happy
      [number_of_cats] = [3]
      {function_name, _, other_stuff} = node

  Bad:
      m = :sad
      [n] = [3]
      {f, _, o} = node
  """

  @behaviour Dogma.Rule

  alias Dogma.Script
  alias Dogma.Error

  def test(script, _config \\ []) do
    script
    |> Script.walk(&check_node(&1, &2))
  end

  defp check_node({:=, meta, [ lhs | rhs ]} = node, errors) do
    if [lhs, rhs] |> Enum.all?(&variable_names_are_longer?/1) do
      {node, errors}
    else
      {node, [error( meta[:line] ) | errors]}
    end
  end
  defp check_node(node, errors) do
    {node, errors}
  end

  for fun <- [:+, :-, :*, :/, :%, :@, :{}, :%{}, :^, :|, :|>, :<>, :%] do
    defp variable_names_are_longer?({unquote(fun),_,value}) do
      variable_names_are_longer?(value)
    end
  end
  defp variable_names_are_longer?({:__aliases__,_,_}), do: true
  defp variable_names_are_longer?({{:.,_,_}, _, _}), do: true
  defp variable_names_are_longer?(lhs) when is_list(lhs) do
    lhs
    |> Enum.all?(&variable_names_are_longer?/1)
  end
  defp variable_names_are_longer?({l,r}) do
    variable_names_are_longer?([l,r])
  end
  defp variable_names_are_longer?({name,_,_}) do
    name_string =
      name
      |> to_string
    String.length(name_string) > 1 || name_string === "_" || name_string === "i"
  end
  defp variable_names_are_longer?(_), do: true

  defp error(pos) do
    %Error{
      rule:    __MODULE__,
      message: """
        Variable names should be more descriptive than just one character
      """,
      line:    pos,
    }
  end
end
