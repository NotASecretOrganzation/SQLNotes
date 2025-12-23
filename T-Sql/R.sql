EXECUTE sp_execute_external_script @language = N'R'
    , @script = N'
a <- 1
b <- 2
c <- a/b
d <- a*b
print(c(c, d))
'