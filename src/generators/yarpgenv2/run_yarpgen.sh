#!/bin/bash

gen_yarpgen() {
    echo "Generating program: $1"
    mkdir ./data/c/test$1
    ./yarpgen --out-dir=./data/c/test$1 --std=c99
    # mv driver.c ./data/c/test$1/driver.c
    # mv func.c ./data/c/test$1/func.c
    # mv init.h ./data/c/test$1/init.h
    # mkdir ./data/c/test$1
    # mv driver.c ./data/c/test$1/driver.c
    # mv func.c ./data/c/test$1/func.c
    clang -S -w -emit-llvm -O0 -o ./data/llO0/driver$1.ll ./data/c/test$1/driver.c
    clang -S -w -emit-llvm -O0 -o ./data/llO0/func$1.ll ./data/c/test$1/func.c
    clang -S -w -emit-llvm -O0 -o ./data/llO0/init$1.ll ./data/c/test$1/init.h
    clang -S -w -emit-llvm -O1 -o ./data/llO1/driver$1.ll ./data/c/test$1/driver.c
    clang -S -w -emit-llvm -O1 -o ./data/llO1/func$1.ll ./data/c/test$1/func.c
    clang -S -w -emit-llvm -O1 -o ./data/llO1/init$1.ll ./data/c/test$1/init.h
    clang -S -w -emit-llvm -O2 -o ./data/llO2/driver$1.ll ./data/c/test$1/driver.c
    clang -S -w -emit-llvm -O2 -o ./data/llO2/func$1.ll ./data/c/test$1/func.c
    clang -S -w -emit-llvm -O2 -o ./data/llO2/init$1.ll ./data/c/test$1/init.h
    # clang -S -emit-llvm -O1 -o ./data/llO1/driver$1.ll -I ./ ./driver.c
    # clang -S -emit-llvm -O1 -o ./data/llO1/func$1.ll -I ./ ./func.c
    # clang -S -emit-llvm -O2 -o ./data/llO2/driver$1.ll -I ./ ./driver.c
    # clang -S -emit-llvm -O2 -o ./data/llO2/func$1.ll -I ./ ./func.c
    # mv driver.c ./data/c/driver$1.c
    # mv func.c ./data/c/func$1.c
    echo "Generate test$1.c"
}

# Run the function in parallel for arguments 1 to 1000
max=1000
for i in $(seq 1 $max); do
    gen_yarpgen $i &
done

# Wait for all background processes to finish
wait