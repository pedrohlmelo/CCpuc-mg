int count_greater(int v[], int n, int L) {
    int c = 0;
    for (int i = 0; i < n; i++)
        if (v[i] > L)
            c++;
    return c;
}

