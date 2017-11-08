# frozen_string_literal: true

require "test_helper"

class BoppersPoloniexTest < Minitest::Test
  setup do
    stub_request(:get, /.+/)
      .to_return(
        status: 200,
        body: File.read("./test/support/response.json"),
        headers: {"Content-Type" => "application/json"}
      )
  end

  test "lints bopper" do
    params = {ticker: "STR", value: "0.00000405", operator: "less_than"}
    bopper = Boppers::Poloniex.new(params)
    Boppers::Testing::BopperLinter.call(bopper)
  end

  test "makes request correctly" do
    params = {ticker: "STR", value: "0.00000405", operator: "less_than"}
    bopper = Boppers::Poloniex.new(params)
    bopper.call

    request = WebMock.requests.last

    assert_equal "https://poloniex.com/public?command=returnTicker",
                 request.uri.normalize.to_s
  end

  test "sends notification" do
    call = nil
    title = "[POLONIEX] STR traded as 0.00000434"
    message = [
      "Volume: 1917.52148220",
      "24h Change: 18.9%",
      "24h High: 0.00000467",
      "24h Low: 0.00000361",
      "",
      "https://poloniex.com/exchange#BTC_STR"
    ].join("\n")

    Boppers
      .expects(:notify)
      .with do |*args|
        call = args
      end
      .once

    params = {ticker: "STR", value: "0.00000435", operator: "less_than"}
    bopper = Boppers::Poloniex.new(params)
    bopper.call

    assert_equal :poloniex, call.first
    assert_equal title, call.last[:title]
    assert_equal message, call.last[:message]
    assert_equal "<b>#{title}</b>", call.last.dig(:options, :telegram, :title)
    assert_equal "HTML", call.last.dig(:options, :telegram, :parse_mode)
    assert call.last.dig(:options, :telegram, :disable_web_page_preview)
  end

  test "notifies only once (less_than operator)" do
    Boppers.expects(:notify).once
    params = {ticker: "STR", value: "0.00000435", operator: "less_than"}
    bopper = Boppers::Poloniex.new(params)

    bopper.call
    bopper.call
  end

  test "notifies only once (greater_than operator)" do
    Boppers.expects(:notify).once
    params = {ticker: "STR", value: "0.00000433", operator: "greater_than"}
    bopper = Boppers::Poloniex.new(params)

    bopper.call
    bopper.call
  end

  test "resends notification after price changing (less_than operator)" do
    payload = JSON.parse(File.read("./test/support/response.json"))
    response1 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    payload["BTC_STR"]["last"] = "0.00000436"
    response2 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    payload["BTC_STR"]["last"] = "0.00000430"
    response3 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    stub_request(:get, /.+/)
      .to_return(response1, response2, response3)

    Boppers.expects(:notify).twice.with do |_, kwargs|
      [
        "[POLONIEX] STR traded as 0.00000434",
        "[POLONIEX] STR traded as 0.00000430"
      ].include?(kwargs[:title])
    end

    params = {ticker: "STR", value: "0.00000435", operator: "less_than"}
    bopper = Boppers::Poloniex.new(params)

    bopper.call
    bopper.call
    bopper.call
  end

  test "resends notification after price changing (greater_than operator)" do
    payload = JSON.parse(File.read("./test/support/response.json"))
    response1 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    payload["BTC_STR"]["last"] = "0.00000432"
    response2 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    payload["BTC_STR"]["last"] = "0.00000437"
    response3 = {
      status: 200,
      body: JSON.dump(payload),
      headers: {"Content-Type" => "application/json"}
    }

    stub_request(:get, /.+/)
      .to_return(response1, response2, response3)

    Boppers.expects(:notify).twice.with do |_, kwargs|
      [
        "[POLONIEX] STR traded as 0.00000434",
        "[POLONIEX] STR traded as 0.00000437"
      ].include?(kwargs[:title])
    end

    params = {ticker: "STR", value: "0.00000433", operator: "greater_than"}
    bopper = Boppers::Poloniex.new(params)

    bopper.call
    bopper.call
    bopper.call
  end
end
