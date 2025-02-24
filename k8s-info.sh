#!/bin/bash
# k8s-info.sh

echo "Analyzing Kubernetes Resources..."
echo "================================"

echo "Deployments:"
for file in k8s/deployments/*.yaml; do
    echo "In $file:"
    grep -E "name:|image:" "$file" | sed 's/^/  /'
done

echo -e "\nServices:"
for file in k8s/services/*.yaml; do
    echo "In $file:"
    grep -E "name:|port:" "$file" | sed 's/^/  /'
done

echo -e "\nStorage:"
for file in k8s/storage/*.yaml; do
    echo "In $file:"
    grep -E "name:|storageClassName:" "$file" | sed 's/^/  /'
done

echo -e "\nConfigMaps/Environment References:"
grep -r "configMapRef\|envFrom" k8s/deployments/
