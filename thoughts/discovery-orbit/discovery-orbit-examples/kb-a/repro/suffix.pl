p(order_1).
p(order_2).
p(abc_12x).
p(item_007).
q :- p(order_1).
r :- order_1 = order_2.
