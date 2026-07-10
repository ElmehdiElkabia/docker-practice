FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt install -y g++ make

COPY Makefile ./

COPY /src /app/

RUN make

CMD ["./app"]