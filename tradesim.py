import math,datetime

def NORMALIZE(x):
  return (x-min(x))/(max(x)-min(x))

def TREND(quote,support,resistance):
  trend = [0]*len(quote.close)
  for x in range(1,len(quote.close)):
    trend[x] = trend[x-1]
    if quote.high[x] >= resistance[x]:
      trend[x] = 1  
    if quote.low[x] <= support[x]:
      trend[x] = -1 
  return trend	

def LAG(price,period):
  lag = [0]*len(price)
  multiplier = 2.0 / (1.0 + period)
  lag[0] = price[0]
  for x in range(1,len(price)):
    lag[x] = ( (price[x] - lag[x-1]) * multiplier) + lag[x-1]
  return lag

def MIN(price,period):
  # n period min
  mn = [0]*len(price)
  for bar in range(1,len(price)):
    tmp = min(price[bar-tmp:bar]) if bar < period else period 
    mn[bar-1] = min(price[bar-tmp:bar])
  return mn

def MAX(price,period):
  # n period max 
  mx = [0]*len(price)
  for bar in range(1,len(price)):
    tmp = min([bar,period]) if bar < period else period
    mx[bar-1] = max(price[bar-tmp:bar])
  return mx
  
def FASTMIN(price,period):
  mn = [0]*len(price)
  mn[0] = price[0]
  for x in range(1,period):
    mn[x] = price[x] if price[x] < mn[x-1] else mn[x-1]

  today = period-1
  outidx = period-1
  lowestidx = -1
  lowestval = 0.0
  trailingidx = 0
        
  while today < len(price):    
    tmp = price[today]
    if lowestidx < trailingidx:
      lowestidx = trailingidx
      lowestval = price[lowestidx]
      i = lowestidx + 1
      while i <= today:
        tmp = price[i]
        if tmp < lowestval:
          lowestidx = i
          lowestval = tmp
        i += 1
            
    elif tmp <= lowestval:
      lowestidx = today
      lowestval = tmp

    mn[outidx] = lowestval
    outidx += 1
    trailingidx += 1
    today += 1
    
  return mn

def FASTMAX(price,period):
  mx = [0]*len(price)
  mx[0] = price[0]
  for x in range(1,period):
    if price[x] > mx[x-1]:
      mx[x] = price[x]
    else:
      mx[x] = mx[x-1]

  today = period-1
  outidx = period-1
  highestidx = -1
  highestval = 0.0
  trailingidx = 0
        
  while today < len(price):
    tmp = price[today] 
    if highestidx < trailingidx:
      highestidx = trailingidx
      highestval = price[highestidx]
      i = highestidx + 1
      while i <= today:
        tmp = price[i]
        if tmp > highestval:
          highestidx = i
          highestval = tmp
        i += 1
            
    elif tmp >= highestval:
      highestidx = today
      highestval = tmp
        
    mx[outidx] = highestval
    outidx += 1
    trailingidx += 1
    today += 1
    
  return mx

def AMA(price,period):
  # Adaptive moving average
  fastend = 0.6667
  slowend = 0.0645
  result = [0]*len(price)
  diff = [0]*len(price)
  for bar in range(1,len(price)):
    diff[bar] = abs(price[bar] - price[bar-1])
  for bar in range(0,len(period)):
    result[bar] = price[bar]
  for bar in range(period,len(price)):
    direction = price[bar] - price[bar-period]
    volatility = sum(diff[bar-period+1:bar])
    efratio = abs(direction/volatility)
    smooth = (efratio*(fastend-slowend)+slowend)**2.0
    result[bar] = result[bar-1] + smooth*(price[bar] - result[bar-1])  
  return result

def SMA(price,period):
  # Simple moving average
  sma = [0]*len(price)
  for x in range(len(price)-period):
    sma[period-1+x] = sum(price[x:x+period])/period
  return sma

def EMA(price,period):
  # Exponential moving average
  ema = [0]*len(price)
  multiplier = 2.0 / (1.0 + period)
  ema[period-1] = sum(price[0:period])/period
  for x in range(0,len(price)-period):
    ema[period+x] = ( (price[period+x] - ema[period-1+x]) * multiplier) + ema[period-1+x]
  return ema

def MO(price,period):
  # Momentum indicator
  mo = [0]*len(price)
  for bar in range(period,len(price)):
    mo[bar] = price[bar] - price[bar-period]
  return mo

def ATR(price,period):
  # Average true range
  tr  = [0]*len(price.close)
  tr[0] = price.high[0] - price.low[0]
  for x in range(1,len(price.close)):
    tr1 = price.high[x] - price.low[x]
    tr2 = price.high[x] - price.close[x-1]
    tr3 = price.close[x-1] - price.low[x]
    tr[x] = max([tr1,tr2,tr3])
  atr = LAG(tr,period)
  return atr

class Quote:
  symbol = ''
  date   = []
  time   = []
  open_  = []
  high   = []
  low    = []
  close  = []
  volume = []

class TspQuote(Quote):
  def __init__(self,filename):
    self.symbol = filename.split('.')[0]
    for line in open(filename,'r'):
      dstring,_open,high,low,close,volume,oi = line.split(',')
      self.date.append(datetime.date(int(dstring[0:4]),int(dstring[4:6]),int(dstring[6:8])))
      self.open_.append(float(_open))
      self.high.append(float(high))
      self.low.append(float(low))
      self.close.append(float(close))
      self.volume.append(float(volume))

class Trade:
  symbol     = ''
  type_      = ''
  units      = 0
  entrydate  = 0
  entryprice = 0
  exitdate   = 0
  exitprice  = 0
  profit     = 0

class Simulator:
  def __init__(self):
    self.strategy = None
    self.runtime = 0
    self.bliss = 0    
  def simulate(self,params):
    starttime = datetime.datetime.now()
    self.strategy.init(params)
    for bar in range(self.strategy.barcount):
      self.strategy.do_bar(bar)
    self.strategy.close_position()
    self.strategy.output()
    self.runtime = datetime.datetime.now() - starttime
    return self.strategy.bliss()
    
class Strategy:
  def __init__(self,quote):
    self.startcash = 0
    self.quote     = quote
    self.symbol    = quote.symbol
    self.date      = quote.date
    self.time      = quote.time
    self.open_     = quote.open_
    self.high      = quote.high
    self.low       = quote.low
    self.close     = quote.close
    self.volume    = quote.volume
    self.barcount  = len(quote.close)

  def setup(self,params):
    raise NotImplementedError('Setup must be implemented')
    
  def rules(self):
    raise NotImplementedError('Rules must be implemented')
    
  def init(self,params):
    self.startbar   = 0
    self.skidfrac   = 0
    self.units      = 0
    self.roundlot   = 0
    self.maxdd      = 0.99
    self.position   = 'flat'
    self.trades     = []
    self.equity     = [0]*self.barcount
    self.balance    = [0]*self.barcount
    self.openprofit = [0]*self.barcount
    self.drawdown   = [0]*self.barcount
    self.buystop    = [0]*self.barcount
    self.sellstop   = [0]*self.barcount
    self.shortstop  = [0]*self.barcount
    self.coverstop  = [0]*self.barcount
    self.setup(params)
    self.balance[0] = self.startcash
    
  def do_bar(self,b):
    self.bar=b
    if self.bar>0:
      self.balance[self.bar] = self.balance[self.bar-1]

    # check if long protective stop was hit
    if (self.position is 'long') and (self.low[self.bar] < self.sellstop[self.bar]):
      bestprice = min([self.open_[self.bar],self.sellstop[self.bar]])
      fillprice = self.slippage(bestprice,self.low[self.bar])
      self.exit_trade(self.date[self.bar],fillprice)

    # check if short protective stop was hit
    if (self.position is 'short') and (self.high[self.bar] > self.coverstop[self.bar]):
      bestprice = max([self.open_[self.bar],self.coverstop[self.bar]])
      fillprice = self.slippage(bestprice,self.high[self.bar])
      self.exit_trade(self.date[self.bar],fillprice)

    # check if entry long stop order was hit
    if (self.position is 'flat') and (self.buystop[self.bar]>0 and self.high[self.bar]>self.buystop[self.bar]):
      bestprice = max([self.open_[self.bar],self.buystop[self.bar],self.low[self.bar]])
      fillprice = self.slippage(self.high[self.bar],bestprice)
      self.enter_trade('long',self.symbol,self.units,self.date[self.bar],fillprice)

    # check if entry short stop order was hit
    if (self.position is 'flat') and (self.low[self.bar]<self.shortstop[self.bar]):
      bestprice = min([self.open_[self.bar],self.shortstop[self.bar],self.high[self.bar]])
      fillprice = self.slippage(self.low[self.bar],bestprice)
      self.enter_trade('short',self.symbol,self.units,self.date[self.bar],fillprice)

    # calculate open profit and equity
    if self.position is 'short': 
      self.openprofit[self.bar] = (self.trades[-1].entryprice-self.close[self.bar]) * self.trades[-1].units
    elif self.position is 'long':  
      self.openprofit[self.bar] = (self.close[self.bar]-self.trades[-1].entryprice) * self.trades[-1].units
        
    self.equity[self.bar]  = self.balance[self.bar] + self.openprofit[self.bar]

    # calculate drawdown
    if self.bar==0:
      self.peak = self.balance[0]
      self.valley = self.balance[0] 
    if self.equity[self.bar] > self.peak: 
      self.peak = self.equity[self.bar]
    if self.equity[self.bar] < self.valley: 
      self.valley = self.equity[self.bar] 
    self.retrace = self.peak-self.valley
    if self.retrace > 0:
      self.drawdown[self.bar] = self.retrace / self.peak
    else:
      self.drawdown[self.bar] = self.drawdown[self.bar-1]

    # execute rules
    if self.bar >= self.startbar and self.bar < self.barcount-1:
      self.rules()

  def buy_open(self):
    if self.position is 'flat':
      fillprice = self.slippage(self.open_[self.bar+1],self.high[self.bar+1])
      self.enter_trade('long',self.symbol,self.units,self.date[self.bar+1],fillprice)

  def sell_open(self):
    if self.position is 'long':
      fillprice = self.slippage(self.open_[self.bar+1],self.low[self.bar+1])
      self.exit_trade(self.date[self.bar+1],fillprice)

  def short_open(self):
    if self.position is 'flat':
      fillprice = self.slippage(self.open_[self.bar+1],self.low[self.bar+1])
      self.enter_trade('short',self.symbol,self.units,self.date[bar+1],fillprice)

  def cover_open(self):
    if self.position is 'short':
      fillprice = self.slippage(self.open_[self.bar+1],self.high[self.bar+1])
      self.exit_trade(self.date[self.bar+1],fillprice)

  def buy_stop(self,price):
    if self.position is 'flat':
      self.buystop[self.bar+1]=price 

  def sell_stop(self,price):
    if self.position is 'long':
      self.sellstop[self.bar+1]=price 

  def short_stop(self,price):
    if self.position is 'flat':
      self.shortstop[self.bar+1]=price 

  def cover_stop(self,price):
    if self.position is 'short':
      self.coverstop[self.bar+1]=price 

  def round_units(self,units):
    return self.roundlot * int((units+0.0001)/self.roundlot+0.5)

  def slippage(self,price1,price2):
    return price1 + self.skidfrac * (price2-price1)

  def enter_trade(self,type_,symbol,units,entrydate,entryprice):
    t = Trade()
    t.type_ = type_
    t.symbol = symbol
    t.units = self.round_units(self.units)
    t.entrydate = entrydate
    t.entryprice = entryprice
    t.exitdate = entrydate
    self.trades.append(t)
    self.position = type_

  def exit_trade(self,date,exitprice):
    if len(self.trades) is 0: 
      return 
    if self.position is 'long':  
      profit = (exitprice-self.trades[-1].entryprice)*self.trades[-1].units
    elif self.position is 'short': 
      profit = (self.trades[-1].entryprice-exitprice)*self.trades[-1].units
    elif self.position is 'flat':
      profit = 0
    self.balance[self.bar] = self.balance[self.bar-1] + profit
    if self.bar < self.barcount-1:
      self.openprofit[self.bar+1] = 0 
    self.trades[-1].exitdate = date
    self.trades[-1].exitprice = exitprice
    self.trades[-1].profit = profit
    self.position='flat'

  def close_position(self):
    if self.position is 'flat': 
      return
    if self.position is 'long':  
      fillprice = self.slippage(self.close[self.bar],self.low[self.bar])
    elif self.position is 'short': 
      fillprice = self.slippage(self.close[self.bar],self.high[self.bar])
    self.exit_trade(self.date[self.bar],fillprice)
    self.openprofit[self.bar] = 0
    self.equity[self.bar] = self.balance[self.bar]

  def output(self):
    trade_log()
    equity_log()
    metrics_log()

  def icagr(self):
    if self.balance[-1] > self.balance[0]:
      ratio = self.balance[-1] / self.balance[0]
      daterangeinyears = int((self.date[-1]-self.date[0]).days / 365.25)
      return math.log(ratio) / daterangeinyears
    else:
      return 0

  def draw_down(self):
    return max(self.drawdown)

  def bliss(self):
    if self.draw_down() > self.maxdd:
      return 0
    else:
      if self.draw_down()>0:
        return self.icagr()/self.draw_down()
      else: 
        return 0

  def metrics_log(self):
    for n in range(self.barcount):
      print "%s OHLC:[ %6.2f %6.2f %6.2f %6.2f ]" % (self.date[n].strftime('%y-%m-%d'),
             self.open_[n],self.high[n],self.low[n],self.close[n])

  def equity_log(self):
    for n in range(self.barcount):
      print "%s %10.2f %10.2f %10.2f" % (self.date[n].strftime('%y-%m-%d'),
             self.balance[n],self.openprofit[n],self.equity[n])

  def trade_log(self):
    for t in self.trades:
      print "%s %s %d %s %7.3f %s %7.3f %6.2f" % (self.symbol,t.type_,t.units,
             t.entrydate.strftime('%y-%m-%d'),t.entryprice,
             t.exitdate.strftime('%y-%m-%d'),t.exitprice,t.profit)

#######################
# Put it all together #
#######################

if __name__ == '__main__':
  
  # Define strategys
  
  class EA(Strategy):
  
    def setup(self,params):
        self.fast      = params[0]
        self.slow      = params[1]
        self.atrmult   = params[2]
        self.heat      = params[3]
        self.atrperiod = params[4]
        self.roundlot  = 250
        self.startbar  = 25
        self.skidfrac  = 0.5
        self.startcash = 1000000
        self.emafast   = LAG(self.close,self.fast)
        self.emaslow   = LAG(self.close,self.slow)
        self.atr       = ATR(self.quote,self.atrperiod)

    def rules(self):
        # money management
        risk = self.atr[self.bar] * self.atrmult
        self.units = self.balance[self.bar] * self.heat / risk

        # buy rule
        if self.emafast[self.bar] > self.emaslow[self.bar]:
          self.buy_open()

        # sell rule
        if self.emafast[self.bar] < self.emaslow[self.bar]:
          self.sell_open()

    def close_position(self):
      fillprice = self.close[-1]
      self.exit_trade(self.date[-1],fillprice)

    def output(self):
      #self.metrics_log()
      self.equity_log()
      self.trade_log()
      print "fast: %d slow: %d atrmult: %d atrperiod: %d heat %5.2f bliss: %6.3f icagr: %6.3f dd: %6.3f" % (
        self.fast,self.slow,self.atrmult,self.atrperiod,self.heat,self.bliss(),self.icagr(),self.draw_down())

    def metrics_log(self):
      for n in range(self.barcount):
        print "%s Eq=%10.2f OHLC:[ %6.2f %6.2f %6.2f %6.2f ] slow=%7.3f fast=%7.3f Atr=%6.3f" % (
               self.date[n].strftime('%y-%m-%d'),self.equity[n],
               self.open_[n],self.high[n],self.low[n],self.close[n],
               self.emaslow[n],self.emafast[n],self.atr[n])

  class SR(Strategy):

    def setup(self,params):
        self.fast      = params[0]
        self.slow      = params[1]
        self.heat      = 0.05
        self.roundlot  = 100
        self.startbar  = 25
        self.skidfrac  = 0.5
        self.startcash = 1000000
        self.fast_r    = FASTMAX(self.high,self.fast)
        self.fast_s    = FASTMIN(self.low,self.fast)
        self.slow_r    = FASTMAX(self.high,self.slow)
        self.slow_s    = FASTMIN(self.low,self.slow)
        self.trend     = TREND(self.quote,self.slow_s,self.slow_r)
    def rules(self):
        # money management
        self.units = self.equity[self.bar] * self.heat / (self.fast_r[self.bar]-self.fast_s[self.bar])

        # buy/sell rules
        if self.trend[self.bar]>0:
          self.buy_stop(self.fast_r[self.bar])
        
        if self.trend[self.bar]<0:
          self.short_stop(self.fast_s[self.bar])
          
        # protective stops
        self.sell_stop(self.fast_s[self.bar])
        self.cover_stop(self.fast_r[self.bar])

    def output(self):
      self.trade_log()
      #self.metrics_log()
      #self.equity_log()
      print "fast: %d slow: %d bliss: %6.3f icagr: %6.3f dd: %6.3f" % (
          self.fast,self.slow,self.bliss(),self.icagr(),self.draw_down())

    def metrics_log(self):
      for n in range(self.barcount):
        print "%s OHLC:[ %6.2f %6.2f %6.2f %6.2f ] [slow:%6.2f/%6.2f fast:%6.2f/%6.2f T: %d]" % (
               self.date[n].strftime('%y-%m-%d'),self.open_[n],self.high[n],self.low[n],
               self.close[n],self.slow_r[n],self.slow_s[n],self.fast_r[n],self.fast_s[n],self.trend[n])

  # Build and run simulator
  sim = Simulator()

  #sim.strategy = EA(TspQuote('sp.csv'))
  #sim.simulate([15,150,5,0.1,20])

  sim.strategy = SR(TspQuote('gc.csv'))
  sim.simulate([20,140])
