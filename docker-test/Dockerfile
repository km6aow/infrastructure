# FROM docker.io/pycontribs/centos:7
FROM docker.io/geerlingguy/docker-ubuntu2404-ansible:latest
RUN groupadd aredn
RUN useradd aredn -g aredn --create-home 
RUN echo "aredn ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
