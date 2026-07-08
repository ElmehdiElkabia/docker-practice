FROM debian:bookworm-slim

WORKDIR /src

RUN apt update -y && apt install -y g++ make

COPY . .

RUN make

CMD [ "./app" ]