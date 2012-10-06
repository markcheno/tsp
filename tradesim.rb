
module Indicators

    def sumArray(ary)
        ary.inject { |sum, value| sum + value }
    end

    def trend(quote,support,resistance)
    
        trend = Array.new(quote.length,0)
        
        for x in 1...quote.length
            trend[x] = trend[x-1]
            trend[x] = 1  if quote.high[x] >= resistance[x]
            trend[x] = -1 if quote.low[x]  <= support[x]
        end
        
        return trend    
    end

    def lag(price,period)

        lag = Array.new(price.length,0)

        multiplier = 2.0 / (1.0 + period)

        lag[0] = price[0]

        # lag(cur) = ( (price(cur) - lag(prev) ) x Multiplier) + lag(prev)
        for x in 1...price.length
            lag[x] = ( (price[x] - lag[x-1]) * multiplier) + lag[x-1]
        end

        return lag
    end

    def min(price,period)

        min = Array.new(price.length,0)

        for bar in 1..price.length
            tmp = period
            tmp = [bar,period].min if bar < period
            min[bar-1] = price.slice(bar-tmp,tmp).min
        end

        return min
    end

    def max(price,period)

        max = Array.new(price.length,0)

        for bar in 1..price.length
            tmp = period
            tmp = [bar,period].min if bar < period
            max[bar-1] = price.slice(bar-tmp,tmp).max
        end

        return max
    end

    def fastmin(price,period)

        min = Array.new(price.length,0)

        min[0] = price[0]
        for x in 1...period
            if price[x] < min[x-1] then
                min[x] = price[x]
            else
                min[x] = min[x-1]
            end
        end

        today = period-1
        outidx = period-1
        lowestidx = -1
        lowestval = 0.0
        trailingidx = 0
        
        while today < price.length
    
            tmp = price[today]
    
            if lowestidx < trailingidx then
        
                lowestidx = trailingidx
                lowestval = price[lowestidx]
                i = lowestidx + 1
                while i <= today
                    tmp = price[i]
                    if tmp < lowestval then
                        lowestidx = i
                        lowestval = tmp
                    end
                    i += 1
                end
            
            elsif tmp <= lowestval then
        
                lowestidx = today
                lowestval = tmp
            
            end
        
            min[outidx] = lowestval
            outidx += 1
            trailingidx += 1
            today += 1
        end
    
        return min
    end

    def fastmax(price,period)

        max = Array.new(price.length,0)

        max[0] = price[0]
        for x in 1...period
            if price[x] > max[x-1] then
                max[x] = price[x]
            else
                max[x] = max[x-1]
            end
        end

        today = period-1
        outidx = period-1
        highestidx = -1
        highestval = 0.0
        trailingidx = 0
        
        while today < price.length
    
            tmp = price[today]
    
            if highestidx < trailingidx then
        
                highestidx = trailingidx
                highestval = price[highestidx]
                i = highestidx + 1
                while i <= today
                    tmp = price[i]
                    if tmp > highestval then
                        highestidx = i
                        highestval = tmp
                    end
                    i += 1
                end
            
            elsif tmp >= highestval then
        
                highestidx = today
                highestval = tmp
            
            end
        
            max[outidx] = highestval
            outidx += 1
            trailingidx += 1
            today += 1
        end
    
        return max
    end

    def ama(price,period)

        # Adaptive moving average
        fastend = 0.6667
        slowend = 0.0645
        result = Array.new(price.length,0)
        diff = Array.new(price.length,0)

        for bar in (1...price.length)
            diff[bar] = (price[bar] - price[bar-1]).abs
        end

        for bar in (0...period)
            result[bar] = price[bar]
        end

        for bar in period...price.length
            direction = price[bar] - price[bar-period]
            volatility = sumArray(diff.slice(bar-period+1..bar))
            efratio = (direction/volatility).abs
            smooth = (efratio*(fastend-slowend)+slowend)**2.0
            result[bar] = result[bar-1] + smooth*(price[bar] - result[bar-1])
        end

        return result
    end

    def sma(price,period)

        # Simple moving average
        sma = Array.new(price.length,0)

        for x in 0..price.length-period
            total = 0
            price.slice(x,period).each { |val| total+=val }
            sma[period-1+x] = total/period
        end

        return sma
    end

    def ema(price,period)

        # Exponential moving average
        ema = Array.new(price.length,0)

        multiplier = 2.0 / (1.0 + period)

        # Calculate the first x-period simple moving average to bootstrap the ema calculation
        total = 0
        price.slice(0,period).each { |val| total+=val }
        ema[period-1] = total/period

        # EMA(current) = ( (Price(current) - EMA(prev) ) x Multiplier) + EMA(prev)
        for x in 0...price.length-period
            ema[period+x] = ( (price[period+x] - ema[period-1+x]) * multiplier) + ema[period-1+x]
        end

        return ema
    end

    def mo(price,period)

        # Momentum indicator
        mo = Array.new(price.length,0)

        for bar in period...price.length
            mo[bar] = price[bar] - price[bar-period]
        end

        return mo
    end

    def atr(price,period)

        # Average true range
        tr  = Array.new(price.length,0)

        tr[0] = price.high[0] - price.low[0]

        for x in 1...price.length
            tr1 = price.high[x] - price.low[x]
            tr2 = price.high[x] - price.close[x-1]
            tr3 = price.close[x-1] - price.low[x]
            tr[x] = [tr1,tr2,tr3].max
        end

        atr = lag(tr,period)

        return atr
    end

end

class Quote
    attr_reader :symbol,:date,:time,:open,:high,:low,:close,:volume,:oi,:length
end

class TspQuote < Quote

    def initialize(filename)

        @symbol = filename.split(".")[0]
        @date   = Array.new
        @time   = Array.new
        @open   = Array.new
        @high   = Array.new
        @low    = Array.new
        @close  = Array.new
        @volume = Array.new
        @oi     = Array.new

        f = File.new(filename)
        pattern = %r{(\d\d\d\d)(\d\d)(\d\d), (\d*.\d*), (\d*.\d*), (\d*.\d*), (\d*.\d*), (\d*), (\d*)}
        for line in f.readlines
                line.scan(pattern) do |year,month,day,open,high,low,close,volume,oi|
                @date   << Time.gm(year,month,day)
                @time   << 0
                @open   << open.to_f
                @high   << high.to_f
                @low    << low.to_f
                @close  << close.to_f
                @volume << volume.to_f
                @oi     << oi.to_f
            end
        end
        f.close
        @length = @date.length
    end
end

class DukasQuote < Quote

    def initialize(filename)

        @symbol = filename.split("_")[0]
        @date   = Array.new
        @time   = Array.new
        @open   = Array.new
        @high   = Array.new
        @low    = Array.new
        @close  = Array.new
        @volume = Array.new
        @oi     = Array.new

        f = File.new(filename)
        pattern = %r{(\d\d)\/(\d\d)\/(\d\d\d\d),(\d\d:\d\d:\d\d),(\d*),(\d*.\d*),(\d*.\d*),(\d*.\d*),(\d*.\d*)}
        for line in f.readlines
            line.scan(pattern) do |month,day,year,time,volume,open,close,low,high|
                @date   << Time.gm(year,month,day)
                @time   << time
                @open   << open.to_f
                @high   << high.to_f
                @low    << low.to_f
                @close  << close.to_f
                @volume << volume.to_i
                @oi     << 0
            end
        end
        f.close
        @length = @date.length
    end
end

class Trade
    attr_accessor :symbol,:type,:units,:entrydate,:entryprice,:exitdate,:exitprice,:profit
end

class Simulator

    attr_accessor :system
    attr_reader   :runtime,:bliss

    def simulate(*params)
        starttime = Time.new
        @system.init(params)
        for bar in 0...@system.barcount
            @system.dobar(bar)
        end
        @system.closeposition
        @system.output
        @runtime = Time.new - starttime
        return @system.bliss
    end
end

class System

    include Indicators

    attr_reader :barcount

    def initialize(quote)
        @startcash = 0
        @quote     = quote
        @symbol    = quote.symbol
        @date      = quote.date
        @time      = quote.time
        @open      = quote.open
        @high      = quote.high
        @low       = quote.low
        @close     = quote.close
        @volume    = quote.volume
        @oi        = quote.oi
        @barcount  = quote.close.length
    end

    def init(params)
        @startbar   = 0
        @skidfrac   = 0
        @units      = 0
        @roundlot   = 0
        @maxdd      = 0.99
        @position   = "flat"
        @trades     = Array.new
        @equity     = Array.new(@barcount,0)
        @balance    = Array.new(@barcount,0)
        @openprofit = Array.new(@barcount,0)
        @drawdown   = Array.new(@barcount,0)
        @buystop    = Array.new(@barcount,0)
        @sellstop   = Array.new(@barcount,0)
        @shortstop  = Array.new(@barcount,0)
        @coverstop  = Array.new(@barcount,0)
        setup(params)
        @balance[0] = @startcash
    end
    
    def dobar(b)

        @bar=b
        @balance[@bar] = @balance[@bar-1] unless @bar==0

        # check if long protective stop was hit
        if @position=="long" and @low[@bar] < @sellstop[@bar] then
            bestprice = [@open[@bar],@sellstop[@bar]].min
            fillprice = skidfunction(bestprice,@low[@bar])
            exittrade(@date[@bar],fillprice)
        end

        # check if short protective stop was hit
        if @position=="short" and @high[@bar] > @coverstop[@bar] then
            bestprice = [@open[@bar],@coverstop[@bar]].max
            fillprice = skidfunction(bestprice,@high[@bar])
            exittrade(@date[@bar],fillprice)
        end

        # check if entry long stop order was hit
        if @position=="flat" and @buystop[@bar]>0 and @high[@bar]>@buystop[@bar] then
            bestprice = [@open[@bar],@buystop[@bar],@low[@bar]].max
            fillprice = skidfunction(@high[@bar],bestprice)
            entertrade("long",@symbol,@units,@date[@bar],fillprice)
        end

        # check if entry short stop order was hit
        if @position=="flat" and @low[@bar]<@shortstop[@bar] then
            bestprice = [@open[@bar],@shortstop[@bar],@high[@bar]].min
            fillprice = skidfunction(@low[@bar],bestprice)
            entertrade("short",@symbol,@units,@date[@bar],fillprice)
        end

        # calculate open profit and equity
        case @position
        when "short"
            @openprofit[@bar] = (@trades[-1].entryprice-@close[@bar]) * @trades[-1].units
        when "long"  
            @openprofit[@bar] = (@close[@bar]-@trades[-1].entryprice) * @trades[-1].units
        end
        
        @equity[@bar]  = @balance[@bar] + @openprofit[@bar]

        # calculate drawdown
        @peak = @valley = @balance[0] if @bar==0
        @peak = @equity[@bar] if @equity[@bar] > @peak
        @valley = @equity[@bar] if @equity[@bar] < @valley
        @retrace = @peak-@valley
        if @retrace > 0 then
            @drawdown[@bar] = @retrace / @peak
        else
            @drawdown[@bar] = @drawdown[@bar-1]
        end

        # execute rules
        rules(@bar) if @bar >= @startbar
    end

    def buyopen
        if @position=="flat" then
            fillprice = skidfunction(@open[@bar+1],@high[@bar+1])
            entertrade("long",@symbol,@units,@date[@bar+1],fillprice)
        end
    end

    def sellopen
        if @position=="long" then
            fillprice = skidfunction(@open[@bar+1],@low[@bar+1])
            exittrade(@date[@bar+1],fillprice)
        end
    end

    def shortopen
        if @position=="flat" then
            fillprice = skidfunction(@open[@bar+1],@low[@bar+1])
            entertrade("short",@symbol,@units,@date[bar+1],fillprice)
        end
    end

    def coveropen
        if @position=="short" then
            fillprice = skidfunction(@open[@bar+1],@high[@bar+1])
            exittrade(@date[@bar+1],fillprice)
        end
    end

    def buystop(price)
        @buystop[@bar+1]=price if @position=="flat"
    end

    def sellstop(price)
        @sellstop[@bar+1]=price if @position=="long"
    end

    def shortstop(price)
        @shortstop[@bar+1]=price if @position=="flat"
    end

    def coverstop(price)
        @coverstop[@bar+1]=price if @position=="short"
    end

    def roundunits(units)
        @roundlot * ((units+0.0001)/@roundlot+0.5).to_i
    end

    def skidfunction(price1,price2)
        price1 + @skidfrac * (price2-price1)
    end

    def entertrade(type,symbol,units,entrydate,entryprice)
        @trades << Trade.new
        @trades[-1].type = type
        @trades[-1].symbol = symbol
        @trades[-1].units = roundunits(@units)
        @trades[-1].entrydate = entrydate
        @trades[-1].entryprice = entryprice
        @trades[-1].exitdate = entrydate
        @trades[-1].exitprice = 0
        @trades[-1].profit = 0
        @position = type
    end

    def exittrade(date,exitprice)
        return if @trades.length==0
        case @position
        when "long"
            profit = (exitprice-@trades[-1].entryprice)*@trades[-1].units
        when "short" 
            profit = (@trades[-1].entryprice-exitprice)*@trades[-1].units
        when "flat"  
            profit = 0
        end
        @balance[@bar] = @balance[@bar-1] + profit
        @openprofit[@bar+1] = 0 if @bar < @barcount-1
        @trades[-1].exitdate = date
        @trades[-1].exitprice = exitprice
        @trades[-1].profit = profit
        @position="flat"
    end

    def closeposition
        return if @position=="flat"
        case @position
        when "long"  
            fillprice = skidfunction(@close[@bar],@low[@bar])
        when "short" 
            fillprice = skidfunction(@close[@bar],@high[@bar])
        end
        exittrade(@date[@bar],fillprice)
        @openprofit[@bar] = 0
        @equity[@bar] = @balance[@bar]
    end

    def output
        tradelog
        equitylog
        metricslog
    end

    def icagr
        if @balance[-1] > @balance[0] then
            ratio = @balance[-1] / @balance[0]
            daterangeinyears = (@date[-1]-@date[0])/60/60/24/365.25
            @icagr = Math.log(ratio) / daterangeinyears
        else
            @icagr = 0
        end
    end

    def drawdown
        @drawdown.max
    end

    def bliss
        if drawdown > @maxdd then
            0
        else
            (drawdown>0) ? (icagr/drawdown) : 0;
        end
    end

    def metricslog
        for n in 0...@barcount
            printf("%s OHLC:[ %6.2f %6.2f %6.2f %6.2f ]\n",
               @date[n].strftime('%y-%m-%d'),
               @open[n],@high[n],@low[n],@close[n])
        end
    end

    def equitylog
        for n in 0...@barcount
            printf("%s %10.2f %10.2f %10.2f\n",
                @date[n].strftime('%y-%m-%d'),
                @balance[n],
                @openprofit[n],
                @equity[n])
        end
    end

    def tradelog
        @trades.each do | t |
            printf("%s %s %d %s %7.3f %s %7.3f %6.2f\n",
                @symbol,
                t.type,
                t.units,
                t.entrydate.strftime('%y-%m-%d'),
                t.entryprice,
                t.exitdate.strftime('%y-%m-%d'),
                t.exitprice,
                t.profit)
        end
    end

end

#######################
# Put it all together #
#######################
if __FILE__ == $0 then

# Define systems

class EA < System

    def setup(params)
        @fast      = params[0]
        @slow      = params[1]
        @atrmult   = params[2]
        @heat      = params[3]
        @atrperiod = params[4]
        @roundlot  = 250
        @startbar  = 25
        @skidfrac  = 0.5
        @startcash = 1_000_000
        @emafast   = lag(@close,@fast)
        @emaslow   = lag(@close,@slow)
        @atr       = atr(@quote,@atrperiod)
    end

    def rules(bar)

        # money management
        risk = @atr[bar] * @atrmult
        @units = @balance[@bar] * @heat / risk

        # buy rule
        buyopen  if @emafast[bar] > @emaslow[bar]

        # sell rule
        sellopen if @emafast[bar] < @emaslow[bar]

    end

    def closeposition
        fillprice = @close[-1]
        exittrade(@date[-1],fillprice)
    end

    def output
        #metricslog
        equitylog
        tradelog
        printf("fast: %d slow: %d atrmult: %d atrperiod: %d heat %5.2f bliss: %6.3f icagr: %6.3f dd: %6.3f\n",@fast,@slow,@atrmult,@atrperiod,@heat,bliss,icagr,drawdown)
    end

    def metricslog
        for n in 0...@barcount
            printf("%s Eq=%10.2f OHLC:[ %6.2f %6.2f %6.2f %6.2f ] slow=%7.3f fast=%7.3f Atr=%6.3f\n",
               @date[n].strftime('%y-%m-%d'),@equity[n],
               @open[n],@high[n],@low[n],@close[n],
               @emaslow[n],@emafast[n],@atr[n])
        end
    end

end

class SR < System

    def setup(params)
        @fast      = params[0]
        @slow      = params[1]
        @heat      = 0.05
        @roundlot  = 100
        @startbar  = 25
        @skidfrac  = 0.5
        @startcash = 1_000_000
        @fast_r    = fastmax(@high,@fast)
        @fast_s    = fastmin(@low,@fast)
        @slow_r    = fastmax(@high,@slow)
        @slow_s    = fastmin(@low,@slow)
        @trend     = trend(@quote,@slow_s,@slow_r)
    end

    def rules(bar)
        # money management
        @units = @equity[bar] * @heat / (@fast_r[bar]-@fast_s[bar])

        # buy/sell rules
        buystop   @fast_r[bar] if @trend[bar]>0
        shortstop @fast_s[bar] if @trend[bar]<0

        # protective stops
        sellstop  @fast_s[bar]
        coverstop @fast_r[bar]
    end

    def output
        tradelog
        #metricslog
        #equitylog        
        printf("fast: %d slow: %d bliss: %6.3f icagr: %6.3f dd: %6.3f\n",@fast,@slow,bliss,icagr,drawdown)
    end

    def metricslog
        for n in 0...@barcount
            printf("%s OHLC:[ %6.2f %6.2f %6.2f %6.2f ] [slow:%6.2f/%6.2f fast:%6.2f/%6.2f T: %d]\n",
               @date[n].strftime('%y-%m-%d'),
               @open[n],@high[n],@low[n],@close[n],
               @slow_r[n],@slow_s[n],
               @fast_r[n],@fast_s[n],
               @trend[n])
        end
    end
end

# Build and run simulator
sim = Simulator.new

sim.system = EA.new(TspQuote.new("sp.csv"))
sim.simulate(15,150,5,0.1,20)

#sim.system = SR.new(TspQuote.new("gc.csv"))
#sim.simulate(20,140)

end