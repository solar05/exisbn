defmodule Exisbn.Tasks.Isbn.UpdateRanges do
  use Mix.Task

  @shortdoc "Uses for library needs to regenerate datasets."

  @moduledoc """
  Uses for library needs to regenerate datasets.
  """

  @default_url "https://www.isbn-international.org/export_rangemessage.xml"
  @output "lib/regions.ex"
  @country_codes_path "priv/country_codes.exs"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [url: :string, xml: :string])

    xml = load_xml(opts)
    country_codes = load_country_codes()
    groups = parse_range_message(xml)

    warn_missing_codes(groups, country_codes)

    dataset = build_dataset(groups, country_codes)
    content = generate_module(dataset)
    File.write!(@output, content)

    Mix.shell().info("Updated #{@output} (#{map_size(dataset)} registration groups)")
  end

  @doc """
  Parses an ISBN RangeMessage XML binary and returns a list of group maps.

  Each map has keys `:prefix`, `:agency`, and `:ranges`, where `:ranges` is a
  list of `[lo, hi]` string pairs with leading zeros preserved.
  """
  @spec parse_range_message(binary()) :: [
          %{prefix: String.t(), agency: String.t(), ranges: [[String.t()]]}
        ]
  def parse_range_message(xml) when is_binary(xml) do
    {doc, _} =
      xml
      |> repair_utf8()
      |> :erlang.binary_to_list()
      |> :xmerl_scan.string(quiet: true)

    doc
    |> xml_find(:RegistrationGroups)
    |> xml_children()
    |> Enum.filter(&xml_element?(&1, :Group))
    |> Enum.map(&parse_group/1)
  end

  @doc """
  Renders the `Exisbn.Regions` module source from a dataset map.

  `module_name` defaults to `"Exisbn.Regions"` and can be overridden in tests
  to avoid redefining the live module.
  """
  @spec generate_module(map(), String.t()) :: String.t()
  def generate_module(dataset, module_name \\ "Exisbn.Regions") do
    entries =
      dataset
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map_join(",\n    ", &format_entry/1)

    """
    defmodule #{module_name} do
      @moduledoc false

      @raw_dataset %{
        #{entries}
      }

      @dataset Map.new(@raw_dataset, fn {prefix, info} ->
                 ranges =
                   Enum.map(info["ranges"], fn [lo, hi] ->
                     {String.to_integer(lo), String.to_integer(hi), String.length(hi)}
                   end)

                 {prefix, Map.put(info, "ranges", ranges)}
               end)

      def dataset, do: @dataset
    end
    """
  end

  defp load_xml(opts) do
    cond do
      path = opts[:xml] ->
        Mix.shell().info("Reading XML from #{path}")
        File.read!(path)

      true ->
        url = opts[:url] || @default_url
        Mix.shell().info("Downloading XML from #{url}")
        download!(url)
    end
  end

  defp download!(url) do
    Application.ensure_all_started(:inets)

    url_charlist = String.to_charlist(url)

    ssl_opts = [{:ssl, [{:verify, :verify_none}]}]

    case :httpc.request(:get, {url_charlist, []}, ssl_opts, []) do
      {:ok, {{_, 200, _}, _, body}} ->
        IO.iodata_to_binary(body)

      {:ok, {{_, status, _}, _, _}} ->
        Mix.raise("HTTP #{status} fetching #{url}")

      {:error, reason} ->
        Mix.raise("Failed to fetch #{url}: #{inspect(reason)}")
    end
  end

  defp load_country_codes do
    if File.exists?(@country_codes_path) do
      {codes, _} = Code.eval_file(@country_codes_path)
      codes
    else
      Mix.shell().info("#{@country_codes_path} not found — all country codes will be nil")
      %{}
    end
  end

  defp warn_missing_codes(groups, country_codes) do
    groups
    |> Enum.reject(fn %{prefix: p} -> Map.has_key?(country_codes, p) end)
    |> Enum.each(fn %{prefix: p, agency: a} ->
      Mix.shell().info("Warning: no country code for #{p} (#{a}), using nil")
    end)
  end

  # Repairs a binary that claims to be UTF-8 but contains isolated Latin-1 bytes
  # (a common issue with the ISBN International XML export).
  # Valid UTF-8 codepoints are passed through unchanged; any byte that does not
  # belong to a valid UTF-8 sequence is re-encoded as its Latin-1 codepoint.
  defp repair_utf8(binary), do: do_repair(binary, [])

  defp do_repair(<<>>, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()
  defp do_repair(<<cp::utf8, rest::binary>>, acc), do: do_repair(rest, [<<cp::utf8>> | acc])
  defp do_repair(<<byte, rest::binary>>, acc), do: do_repair(rest, [<<byte::utf8>> | acc])

  defp parse_group(group_node) do
    rules =
      group_node
      |> xml_find(:Rules)
      |> xml_children()
      |> Enum.filter(&xml_element?(&1, :Rule))

    %{
      prefix: xml_text(group_node, :Prefix),
      agency: xml_text(group_node, :Agency),
      ranges: Enum.flat_map(rules, &parse_rule/1)
    }
  end

  defp parse_rule(rule_node) do
    len = rule_node |> xml_text(:Length) |> String.to_integer()

    if len == 0 do
      []
    else
      [lo_full, hi_full] = rule_node |> xml_text(:Range) |> String.split("-")
      [[String.slice(lo_full, 0, len), String.slice(hi_full, 0, len)]]
    end
  end

  defp xml_element?({:xmlElement, name, _, _, _, _, _, _, _, _, _, _}, name), do: true
  defp xml_element?(_, _), do: false

  defp xml_children({:xmlElement, _, _, _, _, _, _, _, content, _, _, _}), do: content
  defp xml_children(_), do: []

  defp xml_find(node, tag) do
    node |> xml_children() |> Enum.find(&xml_element?(&1, tag))
  end

  defp xml_text(node, tag) do
    node
    |> xml_find(tag)
    |> xml_children()
    |> Enum.find(&match?({:xmlText, _, _, _, _, :text}, &1))
    |> case do
      nil -> ""
      {:xmlText, _, _, _, value, :text} -> List.to_string(value)
    end
  end

  defp build_dataset(groups, country_codes) do
    Map.new(groups, fn %{prefix: prefix, agency: agency, ranges: ranges} ->
      {prefix,
       %{
         "name" => agency,
         "country_code" => Map.get(country_codes, prefix),
         "ranges" => ranges
       }}
    end)
  end

  defp format_entry({prefix, %{"name" => name, "country_code" => cc, "ranges" => ranges}}) do
    ranges_str = Enum.map_join(ranges, ", ", fn [lo, hi] -> ~s(["#{lo}", "#{hi}"]) end)
    cc_str = if cc, do: ~s("#{cc}"), else: "nil"
    safe_name = String.replace(name, "\"", "\\\"")

    ~s("#{prefix}" => %{"name" => "#{safe_name}", "country_code" => #{cc_str}, "ranges" => [#{ranges_str}]})
  end
end
