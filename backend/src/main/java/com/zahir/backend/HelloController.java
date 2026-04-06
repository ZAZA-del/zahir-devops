package com.zahir.backend;

import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello World";
    }

    @GetMapping("/health")
    public String health() {
        return "{\"status\":\"UP\"}";
    }

    @GetMapping("/api/info")
    public String info() {
        return "{\"project\":\"Zahir DevOps\",\"stack\":{\"backend\":\"Java Spring Boot\",\"frontend\":\"Angular\",\"k8s\":\"EKS\",\"logging\":\"Elasticsearch + Kibana\"}}";
    }
}
