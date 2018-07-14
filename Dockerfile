FROM alpine
MAINTAINER skandyla@gmail.com
RUN apk add --update ca-certificates
ARG GIT_COMMIT=unknown
ARG GIT_BRANCH=unknown
LABEL git-commit=$GIT_COMMIT
LABEL git-branch=$GIT_BRANCH
ADD main .
ENV PORT 8080
EXPOSE 8080
USER nobody
ENTRYPOINT ["/main"]


#FROM alpine:latest as build
#RUN apk add --no-cache ca-certificates

#FROM scratch
#LABEL maintainer="skandyla@gmail.com"
#COPY main /main
#COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
#COPY --from=build /etc/passwd /etc/passwd
#ENV PORT 8080
#EXPOSE 8080
#USER nobody
#ENTRYPOINT ["/main"]