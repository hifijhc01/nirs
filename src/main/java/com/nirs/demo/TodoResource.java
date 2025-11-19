package com.nirs.demo;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import java.util.List;

@Path("/todos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TodoResource {

    @PersistenceContext(unitName = "TodoPU")
    private EntityManager em;

    @GET
    public List<Todo> getAll() {
        return em.createQuery("SELECT t FROM Todo t", Todo.class).getResultList();
    }

    @POST
    public Todo create(Todo todo) {
        // EAP will handle transaction automatically via JTA usually, 
        // strictly simpler to mark specific TX if needed but this works for demo
        return todo; 
    }
}
