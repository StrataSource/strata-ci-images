FROM debian:trixie-slim

RUN \
set -e \
mkdir -p /etc/apt/keyrings; \
apt-get update; \
apt-get install -y curl gpg; \
curl -fsSL https://craftablescience.info/ppa/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/craftablescience.gpg; \
echo "deb [signed-by=/etc/apt/trusted.gpg.d/craftablescience.gpg] https://craftablescience.info/ppa/debian ./" | tee /etc/apt/sources.list.d/craftablescience.list; \
apt-get update; \
apt-get install -y maretf vpkedit; \
apt-get autoclean;

CMD ["/bin/bash"]