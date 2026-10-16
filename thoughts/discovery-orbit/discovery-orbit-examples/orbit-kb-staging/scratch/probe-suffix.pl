% Does s(CASP) 1.1.4 strip a _<digits> suffix from atoms?
p(log_4417).
p(order_4417).
p(m_now).
q :- p(log).
r :- p(log_4417).
s(X) :- p(X), X \= log.
