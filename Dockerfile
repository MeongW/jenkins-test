FROM openjdk:17-alpine

COPY ../build/libs/*SNAPSHOT.jar /app.jar

ENTRYPOINT ["java", "-jar", "-Duser.timezone=Asia/Seoul", "/app.jar"]