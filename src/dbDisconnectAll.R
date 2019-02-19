# Quick function to disconnect all SQL connections since there can be only 16
# concurrent connections.  Use liberally!

dbDisconnectAll <- function(){
  ile <- length(dbListConnections(MySQL())  )
  lapply( dbListConnections(MySQL()), function(x) dbDisconnect(x) )
  cat(sprintf("%s connection(s) closed.\n", ile))
}

dbDisconnectAll()