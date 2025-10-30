# 이 FROM은 OpenShift의 dockerStrategy.from 설정에 의해 실제 빌드 시 무시됩니다.
FROM scratch

# OpenShift의 random UID 실행을 고려한 권한 설정
USER 0
RUN mkdir -p /opt/eap/standalone/deployments \
 && chown -R 0:0 /opt/eap \
 && chmod -R g+rwX /opt/eap

# WAR 배치 (파일명: ROOT.war 기준)
COPY ROOT.war /opt/eap/standalone/deployments/ROOT.war

EXPOSE 8080 8443 9990
USER 185

