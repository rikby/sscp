FROM centos:7

#Add repos
RUN  rpm -U https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum update && yum install -y  \
  sudo \
  openssh-clients \
  openssh-server \
  && yum -y clean all

# Add test user
RUN useradd tuser -u1000

VOLUME /code

####### Enable SSH access ########
# https://docs.docker.com/engine/examples/running_ssh_service/
RUN mkdir /var/run/sshd -p
RUN echo 'root:dev' | chpasswd
RUN echo 'tuser:dev' | chpasswd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE 'in users profile'
RUN echo 'export VISIBLE=now' >> /etc/profile

EXPOSE 22
# ---------
# prevent notices on SSH login
RUN touch /var/log/lastlog

COPY tests/sshd_config /etc/ssh/sshd_config
RUN ssh-keygen -t rsa1 -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t dsa  -f /etc/ssh/ssh_host_dsa_key

# Install authorized key for root and tuser user
COPY tests/id_rsa.pub /root/
RUN mkdir -p /root/.ssh /home/tuser/.ssh && \
    cat /root/id_rsa.pub >> /root/.ssh/authorized_keys && \
    rm -f /root/id_rsa.pub && \
    chmod og-rwx -R /root/.ssh && \
    cp -r /root/.ssh /home/tuser/ && \
    chown tuser:tuser -R /home/tuser/.ssh
####### EOB Enable ssh access #######

# Add tuser user into sudoers
RUN echo 'tuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN curl -Ls https://github.com/sstephenson/bats/archive/master.tar.gz | tar -C /root -xzf - \
  && bash /root/bats-master/install.sh /usr/local

COPY tests/.bashrc /root/
COPY tests/.bashrc /home/tuser/

# add .ssh/config
RUN mkdir -p /root/.ssh /home/tuser/.ssh
COPY tests/ssh_config /root/.ssh/config
COPY tests/ssh_config /home/tuser/.ssh/config
RUN chmod go-rwx -R /root/.ssh /home/tuser/.ssh

COPY tests/enterpoint.sh /root/
RUN chmod +x /root/enterpoint.sh
ENTRYPOINT /root/enterpoint.sh /usr/sbin/sshd -D -e

