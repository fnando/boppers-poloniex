# frozen_string_literal: true

require "bigdecimal"
require "boppers/poloniex/version"

module Boppers
  class Poloniex
    attr_reader :ticker, :operator, :expected_value,
                :already_notified, :interval

    def initialize(ticker:, operator:, value:, interval: 15)
      @ticker = ticker
      @operator = operator
      @expected_value = BigDecimal(value)
      @interval = interval
      @already_notified = false
    end

    def call
      ticker_info = fetch_ticker(ticker)
      current_value = BigDecimal(ticker_info.fetch("last"))
      public_send(operator, ticker_info, current_value)
    end

    def greater_than(ticker_info, current_value)
      if current_value > expected_value
        notify(ticker_info) unless already_notified
      else
        @already_notified = false
      end
    end

    def less_than(ticker_info, current_value)
      if current_value < expected_value
        notify(ticker_info) unless already_notified
      else
        @already_notified = false
      end
    end

    private def notify(ticker_info)
      last = ticker_info["last"]
      change = (BigDecimal(ticker_info["percentChange"]) * 100).to_f.round(2)
      volume = ticker_info["baseVolume"]
      high = ticker_info["high24hr"]
      low = ticker_info["low24hr"]

      title = "[POLONIEX] #{ticker} traded as #{last}"
      message = [
        "Volume: #{volume}",
        "24h Change: #{change}%",
        "24h High: #{high}",
        "24h Low: #{low}",
        "",
        "https://poloniex.com/exchange#BTC_#{ticker}"
      ].join("\n")

      options = {
        telegram: {
          disable_web_page_preview: true,
          parse_mode: "HTML",
          title: "<b>#{title}</b>"
        }
      }

      Boppers.notify(:poloniex,
                     title: title,
                     message: message,
                     options: options)
      @already_notified = true
    end

    private def fetch_ticker(ticker)
      response = Boppers::HttpClient.get do
        url "https://poloniex.com/public?command=returnTicker"
        options expect: 200
      end

      response.data.fetch("BTC_#{ticker}")
    end
  end
end
