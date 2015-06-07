# coding: utf-8

require 'oanda_api'
require 'jiji/model/securities/internal/oanda/converter'

module Jiji::Model::Securities::Internal::Oanda
  module RateRetriever
    include Jiji::Errors
    include Jiji::Model::Trading

    def retrieve_pairs
      @client.instruments({
        account_id: @account.account_id,
        fields:     %w(displayName pip maxTradeUnits precision marginRate)
      }).get.map { |item| convert_response_to_pair(item) }
    end

    def retrieve_current_tick
      prices = @client.prices(instruments: retrieve_all_pairs).get
      convert_response_to_ticks(prices)
    end

    def retrieve_tick_history(pair_name, start_time, end_time)
      ticks = retrieve_candles(pair_name, 'S15', start_time, end_time).get
      convert_and_fill_ticks(ticks, pair_name, start_time, end_time)
    end

    def retrieve_rate_history(pair_name, interval, start_time, end_time)
      granularity = Converter.convert_interval_to_granularity(interval)
      retrieve_candles(pair_name,
        granularity, start_time, end_time).get.map do |item|
        convert_response_to_rate(pair_name, item)
      end
    end

    private

    def retrieve_all_pairs
      @all_pairs ||= retrieve_pairs.map { |v| v.internal_id }
    end

    def retrieve_candles(pair_name, interval,
      start_time, end_time, candle_format = 'bidask')
      @client.candles({
        instrument:    Converter.convert_pair_name_to_instrument(pair_name),
        granularity:   interval,
        candle_format: candle_format,
        start:         start_time.utc.to_datetime.rfc3339,
        end:           end_time.utc.to_datetime.rfc3339
      })
    end

    def convert_response_to_pair(item)
      Pair.new(
        Converter.convert_instrument_to_pair_name(item.instrument),
        item.instrument, item.pip.to_f, item.max_trade_units.to_i,
        item.precision.to_f, item.margin_rate.to_f)
    end

    def convert_response_to_ticks(prices)
      timestamp = nil
      values = prices.each_with_object({}) do |p, r|
        timestamp ||= p.time
        pair_name = Converter.convert_instrument_to_pair_name(p.instrument)
        r[pair_name] = Tick::Value.new(p.ask.to_f, p.bid.to_f)
      end
      Tick.new(values, timestamp)
    end

    def convert_response_to_rate(pair_name, item)
      Rate.new(pair_name, item.time,
        convert_response_to_tick_value('open',  item),
        convert_response_to_tick_value('close', item),
        convert_response_to_tick_value('high',  item),
        convert_response_to_tick_value('low',   item))
    end

    def convert_response_to_tick(price, pair_name,
      bid = price.open_bid, ask = price.open_ask)
      values = {}
      values[pair_name] = Tick::Value.new(bid.to_f, ask.to_f)
      Tick.new(values, price.time)
    end

    def convert_response_to_tick_value(id, item)
      Tick::Value.new(
        item.method("#{id}_bid").call.to_f,
        item.method("#{id}_ask").call.to_f)
    end

    def convert_and_fill_ticks(ticks, pair_name, start_time, end_time)
      prev = resolve_latest_tick(ticks, start_time, pair_name)
      array = ticks.each_with_object([]) do |item, a|
        fill_ticks(a, prev, pair_name, item.time)
        prev = item
        a << create_tick(pair_name, item.open_bid, item.open_ask, item.time)
      end
      fill_ticks(array, prev, pair_name, end_time)
      array
    end

    def fill_ticks(array, prev, pair_name, to)
      t = prev.time
      while (t += 15) < to
        array << create_tick(pair_name, prev.close_bid, prev.close_ask, t)
      end
    end

    def resolve_latest_tick(ticks, start_time, pair_name)
      if !ticks.empty? && ticks.first.time == start_time
        ticks.first
      else
        latest = retrieve_latest_tick(pair_name, start_time)
        latest.time = start_time - 15
        latest
      end
    end

    def retrieve_latest_tick(pair_name, start_time)
      time = start_time - 15
      loop do
        ticks = retrieve_candles(
          pair_name, 'S15', time - (60 * 60 * 12), time).get
        return ticks.last unless ticks.empty?
        time -= (60 * 60 * 12)
      end
    end

    def create_tick(pair_name, bid, ask, time)
      values = {}
      values[pair_name] = Tick::Value.new(bid.to_f, ask.to_f)
      Tick.new(values, time)
    end
  end
end