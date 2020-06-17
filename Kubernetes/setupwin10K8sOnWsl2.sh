#!/bin/bash
echo If running WSL on Windows 10 this script will configure Kubernetes CLI.
KUBECTLEXEC=/usr/local/bin/kubectl
if [[ $(grep Microsoft /proc/version) ]]; then
	echo "WSL is running on Windows 10"
	if ([ -f "$KUBECTLEXEC" ] && [ -x "$KUBECTLEXEC" ]); then
		echo "Good: File '$KUBECTLEXEC' is executable"
	else
		echo "WARNING: File '$KUBECTLEXEC' is not executable or not found, now trying to download it."

		echo
		echo Install kubectl cli
		echo
		curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
		chmod +x ./kubectl
		sudo mv ./kubectl /usr/local/bin/kubectl
	fi
	KUBECONFIG=~/.kube/config
	if ([ -f "$KUBECONFIG" ]); then
		echo "Good: File '$KUBECONFIG' exists"
	else
		echo "WARNING: File '$KUBECONFIG' is not available, now trying to create it."
		echo
		echo Copy windows config
		echo
		mkdir ~/.kube
		WINUSERNAME=$(cmd.exe /c "echo %USERNAME%")
		WINUSERNAME=${WINUSERNAME%$'\r'}   # Remove trailing return.
		WINUSERNAME=${WINUSERNAME%$'\n'}   # Remove trailing newline.
		cp /mnt/c/Users/$WINUSERNAME/.kube/config ~/.kube

		echo Set kubectl context
		kubectl config use-context docker-for-desktop
	fi
else
	echo WSL on Windows 10 was not detected.
fi

echo Check that kubectl works.
kubectl cluster-info | grep "running"

