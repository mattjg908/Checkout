defmodule CheckoutTest do
  use ExUnit.Case, async: true
  doctest Checkout
  use PropCheck

  property "sums without specials" do
    forall {item_list, expected_price, price_list} <- item_price_list() do
      expected_price == Checkout.total(item_list, price_list, [])
    end
  end

  property "sums without specials (but with metrics)", [:verbose] do
    forall {item_list, expected_price, price_list} <- item_price_list() do
      (expected_price == Checkout.total(item_list, price_list, []))
      |> collect(MetricsHelper.bucket(length(item_list), 10))
    end
  end

  property "sums including specials" do
    forall {items, expected_price, prices, specials} <- item_price_special() do
      expected_price == Checkout.total(items, prices, specials)
    end
  end

  defp item_price_special() do
    # first let: freeze the price list
    let price_list <- price_list() do
      # second let: freeze the list of specials
      let special_list <- special_list(price_list) do
        # third let: regular + special items and prices
        let {{regular_items, regular_expected}, {special_items, special_expected}} <-
              {regular_gen(price_list, special_list), special_gen(price_list, special_list)} do
          # and merge + return initial lists:
          {Enum.shuffle(regular_items ++ special_items), regular_expected + special_expected,
           price_list, special_list}
        end
      end
    end
  end

  defp special_list(price_list) do
    items = for {name, _} <- price_list, do: name

    let specials <- list({elements(items), choose(2, 5), integer()}) do
      sorted = Enum.sort(specials)
      IO.inspect "before: #{sorted}"
      deduped = Enum.dedup_by(sorted, fn {x, _, _} -> x end)
      IO.inspect "after: #{deduped}"
    end
  end

  defp item_price_list do
    let price_list <- price_list() do
      let {item_list, expected_price} <- item_list(price_list) do
        {item_list, expected_price, price_list}
      end
    end
  end

  defp price_list do
    let price_list <- non_empty(list({non_empty(utf8()), integer()})) do
      :lists.ukeysort(1, price_list)
    end
  end

  defp item_list(price_list) do
    sized(size, item_list(size, price_list, {[], 0}))
  end

  defp item_list(0, _, acc), do: acc

  defp item_list(n, price_list, {item_acc, price_acc}) do
    let {item, price} <- elements(price_list) do
      item_list(n - 1, price_list, {[item | item_acc], price + price_acc})
    end
  end
end
