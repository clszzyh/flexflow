defprotocol Flexflow.ProcessTracker do
  def ping(o)
end

defprotocol Flexflow.ActivityTracker do
  def ping(o)
end

defprotocol Flexflow.GatewayTracker do
  def ping(o)
end
