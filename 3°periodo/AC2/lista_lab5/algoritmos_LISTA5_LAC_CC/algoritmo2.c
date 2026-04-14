int linear(int v[], int n, int x) {
    for (int i = 0; i < n; i++)
        if (v[i] == x)
            return i;
    return -1;
}

