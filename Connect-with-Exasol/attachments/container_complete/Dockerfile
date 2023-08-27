FROM ubuntu:18.04 AS cloudbeaver_build

RUN apt-get -y update
RUN apt-get -y install curl gnupg2

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN apt-get -y update && \
    apt-get -y install \
               openjdk-11-jdk \
               maven  \
               yarn \
               nodejs \
               git \
               xmlstarlet

RUN npm install -g lerna


RUN git clone https://github.com/dbeaver/cloudbeaver.git

RUN xmlstarlet ed \
    -s "/plugin/extension[@point='org.jkiss.dbeaver.resources']" -t elem -n resource -v "" \
    -i "/plugin/extension[@point='org.jkiss.dbeaver.resources']/resource[not(@*)]" -t attr -n name -v drivers/exasol \
    -s "/plugin/extension[@point='org.jkiss.dbeaver.product.bundles']" -t elem -n bundle -v "" \
    -i "/plugin/extension[@point='org.jkiss.dbeaver.product.bundles']/bundle[not(@*)]" -t attr -n id -v drivers.exasol \
    -i "/plugin/extension[@point='org.jkiss.dbeaver.product.bundles']/bundle[@id='drivers.exasol']" -t attr -n label -v "Exasol drivers" \
    -s "/plugin/extension[@point='io.cloudbeaver.driver']" -t elem -n driver -v "" \
    -i "/plugin/extension[@point='io.cloudbeaver.driver']/driver[not(@*)]" -t attr -n id -v exasol:exasol \
    ./cloudbeaver/server/bundles/io.cloudbeaver.resources.drivers.base/plugin.xml \
    > /tmp/plugin.xml

RUN mv /tmp/plugin.xml ./cloudbeaver/server/bundles/io.cloudbeaver.resources.drivers.base/

RUN xmlstarlet ed -N my=http://maven.apache.org/POM/4.0.0 -s "/my:project/my:modules" -t elem -n module -v "exasol" ./cloudbeaver/server/drivers/pom.xml > /tmp/pom.xml

RUN mv /tmp/pom.xml ./cloudbeaver/server/drivers/pom.xml

RUN mkdir ./cloudbeaver/server/drivers/exasol
COPY ./pom.xml ./cloudbeaver/server/drivers/exasol/ 



RUN cd cloudbeaver/deploy; bash ./build.sh


FROM adoptopenjdk/openjdk11:jdk-11.0.10_9-ubuntu-slim

COPY --from=cloudbeaver_build cloudbeaver/deploy/cloudbeaver /opt/cloudbeaver

EXPOSE 8978

WORKDIR /opt/cloudbeaver/
ENTRYPOINT ["./run-server.sh"]
