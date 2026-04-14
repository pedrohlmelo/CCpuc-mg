.data
vetor:    .word 5, 4, 3, 2, 1      # vetor com 5 elementos
n:        .word 5                   # tamanho do vetor

.text
.globl main

main:
    # a0 = endereço do vetor
    la a0, vetor

    # a1 = tamanho do vetor
    lw a1, n

    # a2 = valor a ser buscado
    li a2, 3        # <<< PROCURA O NÚMERO 3 (altere se quiser)

    # chama função ls (Linear Search)
    jal ra, ls

    # agora o resultado está em a0:
    # se encontrou → a0 = índice
    # se não → a0 = -1

    # guardando resultado em um registrador válido
    mv s0, a0        # salva o resultado em s0 (safe register)

    # encerra corretamente o programa
    li a7, 10
    ecall


# --------------------------------------------------
# FUNÇÃO: ls (linear search)
# a0 = endereço do vetor
# a1 = tamanho do vetor
# a2 = valor buscado
# return: a0 = índice ou -1
# --------------------------------------------------

ls:
    add  t0, zero, zero        # i = 0

ls_loop:
    bge  t0, a1, ls_not_found  # if i >= n: fim

    slli t1, t0, 2              # offset = i * 4
    add  t1, a0, t1             # endereço do elemento
    lw   t2, 0(t1)              # t2 = v[i]

    beq  t2, a2, ls_found       # se v[i] == valor, achou

    addi t0, t0, 1              # i++
    j    ls_loop


ls_found:
    add  a0, t0, zero           # return índice
    j fim   # loop infinito

fim:
    j fim   # loop infinito

ls_not_found:
    addi a0, zero, -1           # return -1
    j fim

