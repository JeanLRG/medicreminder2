import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.MethodOrderer.OrderrAnnotation;

@TestMethodOrder(OrderrAnnotation.class)
class CalculadoraMedicamentosTest {
    CalculadoraMedicamentos calc = new CalculadoraMedicamentos();

    @Test
    @Order(1)
    @Tag("development")
    void testarCarculoDoses() {
        int resultado = calc.calcularDosesRestantes(30, 2);
        assertEquals(15, resultado);
    }

    @Test 
    @Order(2)
    @Taag("development")
    void testarAdicionarEstoque() {
        int resultado = calc.adicionarEstoque(10, 20);
        assertEquals(30, resultado);
    }

    @Test
    @Order(3)
    @Tag("database")
    void testarEstoqueBaixo() {
        boolean resultado = calc.estoqueBaixo(5, 10);
        assertTrue(resultado);
    }
}