.data
vetor:    .word 3, 10, 7, 2, 15    # 5 elementos
n:        .word 5
L:        .word 6                   # valor de referência

.text
.globl main

main:

    # a0 = endereço do vetor
    la a0, vetor

    # a1 = tamanho do vetor
    lw a1, n

    # a2 = valor de referência (L)
    lw a2, L

    # chama função count_gt
    jal ra, count_gt

    # guarda o resultado em um registrador seguro
    mv s0, a0        # s0 = quantidade de valores > L

    # encerra corretamente
    li a7, 10
    ecall


# -------------------------------------------------
# FUNÇÃO: count_gt
# a0 = endereço do vetor
# a1 = tamanho
# a2 = valor L
# retorno (a0) = quantidade de elementos > L
# -------------------------------------------------

count_gt:
    li t0, 0                  # count = 0
    li t1, 0                  # i = 0

gt_loop:
    bge  t1, a1, gt_end       # if i >= n, fim

    slli t2, t1, 2            # offset = i * 4
    add  t2, a0, t2
    lw   t3, 0(t2)            # t3 = v[i]

    ble  t3, a2, gt_skip      # if v[i] <= L, skip
    addi t0, t0, 1            # count++

gt_skip:
    addi t1, t1, 1            # i++
    j    gt_loop

gt_end:
    mv   a0, t0               # return count
    j    fim
    
fim:
    j    fim

