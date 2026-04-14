def max_v(v):
    m = v[0]
    for x in v[1:]:
        if x > m:
            m = x
    return m

