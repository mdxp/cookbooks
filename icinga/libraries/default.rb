def icinga_boolean(true_or_false)
  true_or_false ? "1" : "0"
end

def icinga_interval(seconds)
  if seconds.to_i < node['icinga']['interval_length'].to_i
    raise ArgumentError, "Specified icinga interval of #{seconds} seconds must be equal to or greater than the default interval length of #{node['icinga']['interval_length']}"
  end
  interval = seconds / node['icinga']['interval_length']
  interval
end

def icinga_attr(name)
  node['icinga'][name]
end
