#Step-1: Installing Git, Java-1.8.0, Maven
sudo yum stall git java-1.8.0 maven -y

#Step-2: Gettin Repo (jenkins.io --> download --> redhat)
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key

#Step-3: Download Java (the version that supported by Jenkins)
sudo yum install java-17-amazon-corretto -y
sudo yum install jenkins -y
update-alternatives --config java

#Step-4: Restarting Jenkins (when we download any service it will be on stop state)
systemctl start jenkins.service
systemctl enable jenkins.service
systemctl status jenkins.service

