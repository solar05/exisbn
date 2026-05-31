defmodule Mix.Tasks.Isbn.UpdateRangesTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Isbn.UpdateRanges

  @fixture_xml File.read!("test/fixtures/sample_rangemessage.xml")

  describe "parse_range_message/1" do
    test "returns one map per Group element" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      assert length(groups) == 5
    end

    test "extracts :prefix and :agency for each group" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      eng = Enum.find(groups, &(&1.prefix == "978-0"))
      assert eng.agency == "English language"
    end

    test "converts Range+Length into [lo, hi] string pairs" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      brazil = Enum.find(groups, &(&1.prefix == "978-85"))

      assert [["00", "19"], ["200", "549"] | _] = brazil.ranges
    end

    test "preserves leading zeros in lo/hi" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      eng = Enum.find(groups, &(&1.prefix == "978-0"))

      assert ["00", "19"] in eng.ranges
      assert ["9500000", "9999999"] in eng.ranges
    end

    test "skips rules with Length 0" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      us = Enum.find(groups, &(&1.prefix == "979-8"))

      # Rule with Length 0 must be absent; only the length>0 rules remain
      assert [["1950", "1999"], ["200", "239"]] = us.ranges
    end

    test "groups with all-zero Length rules produce empty ranges list" do
      groups = UpdateRanges.parse_range_message(@fixture_xml)
      thailand = Enum.find(groups, &(&1.prefix == "978-611"))

      assert thailand.ranges == []
    end
  end

  describe "generate_module/2" do
    @simple_dataset %{
      "978-85" => %{
        "name" => "Brazil",
        "country_code" => "BR",
        "ranges" => [["00", "19"], ["200", "549"]]
      }
    }

    test "produces a defmodule block" do
      code = UpdateRanges.generate_module(@simple_dataset)
      assert code =~ "defmodule Exisbn.Regions"
    end

    test "respects the optional module_name argument" do
      code = UpdateRanges.generate_module(@simple_dataset, "My.TestRegions")
      assert code =~ "defmodule My.TestRegions"
      refute code =~ "defmodule Exisbn.Regions"
    end

    test "embeds the prefix and name in the output" do
      code = UpdateRanges.generate_module(@simple_dataset)
      assert code =~ ~s("978-85")
      assert code =~ ~s("Brazil")
    end

    test "embeds the country code string" do
      code = UpdateRanges.generate_module(@simple_dataset)
      assert code =~ ~s("BR")
    end

    test "renders nil country code without quotes" do
      dataset = %{
        "978-0" => %{
          "name" => "English language",
          "country_code" => nil,
          "ranges" => [["00", "19"]]
        }
      }

      code = UpdateRanges.generate_module(dataset)
      assert code =~ "\"country_code\" => nil"
    end

    test "escapes double quotes inside names" do
      dataset = %{
        "978-XX" => %{"name" => ~s(Foo "Bar"), "country_code" => nil, "ranges" => []}
      }

      code = UpdateRanges.generate_module(dataset)
      assert code =~ ~s(Foo \\"Bar\\")
    end

    test "entries are sorted by prefix" do
      dataset = %{
        "978-9" => %{"name" => "Z", "country_code" => nil, "ranges" => []},
        "978-1" => %{"name" => "A", "country_code" => nil, "ranges" => []}
      }

      code = UpdateRanges.generate_module(dataset)
      pos_1 = :binary.match(code, ~s("978-1")) |> elem(0)
      pos_9 = :binary.match(code, ~s("978-9")) |> elem(0)
      assert pos_1 < pos_9
    end

    test "produced source is valid Elixir syntax" do
      code = UpdateRanges.generate_module(@simple_dataset)
      assert {:ok, _} = Code.string_to_quoted(code)
    end

    test "generated module compiles and returns correct dataset" do
      name_str = "TestRegions#{System.unique_integer([:positive])}"
      module_atom = String.to_atom("Elixir.#{name_str}")

      dataset = %{
        "978-85" => %{
          "name" => "Brazil",
          "country_code" => "BR",
          "ranges" => [["00", "19"], ["200", "549"]]
        },
        "978-0" => %{
          "name" => "English language",
          "country_code" => nil,
          "ranges" => [["00", "19"], ["200", "699"]]
        }
      }

      code = UpdateRanges.generate_module(dataset, name_str)

      [{^module_atom, _}] = Code.compile_string(code)

      compiled = module_atom.dataset()

      assert Map.has_key?(compiled, "978-85")
      assert compiled["978-85"]["name"] == "Brazil"
      assert compiled["978-85"]["country_code"] == "BR"
      assert compiled["978-85"]["ranges"] == [{0, 19, 2}, {200, 549, 3}]

      assert compiled["978-0"]["country_code"] == nil

      :code.purge(module_atom)
      :code.delete(module_atom)
    end
  end

  describe "round-trip parse → generate" do
    test "round-trip produces a compilable module with correct range tuples" do
      country_codes = %{"978-85" => "BR", "978-0" => nil, "979-8" => "US"}
      groups = UpdateRanges.parse_range_message(@fixture_xml)

      dataset =
        Map.new(groups, fn %{prefix: p, agency: a, ranges: r} ->
          {p, %{"name" => a, "country_code" => Map.get(country_codes, p), "ranges" => r}}
        end)

      name_str = "RoundTripRegions#{System.unique_integer([:positive])}"
      module_atom = String.to_atom("Elixir.#{name_str}")
      code = UpdateRanges.generate_module(dataset, name_str)

      assert {:ok, _} = Code.string_to_quoted(code)

      [{^module_atom, _}] = Code.compile_string(code)

      compiled = module_atom.dataset()

      # Brazil ranges from fixture
      brazil = compiled["978-85"]
      assert brazil["country_code"] == "BR"
      assert {0, 19, 2} in brazil["ranges"]
      assert {200, 549, 3} in brazil["ranges"]

      # Groups with all-zero lengths should have empty ranges
      assert compiled["978-611"]["ranges"] == []

      :code.purge(module_atom)
      :code.delete(module_atom)
    end
  end
end
