mv ~/Downloads/civo-k8s_demo_1-kubeconfig $HOME/.kube/config
kubectl config use-context
kubectl config view
k get pods --all-namespaces
k get pods --namespace nginx1
k get pods
kubectl logs --follow nginx1-56c6c9f45f-9h6hz
kubectl exec --stdin --tty nginx1-56c6c9f45f-9h6hz -- /bin/bash
  

      



          