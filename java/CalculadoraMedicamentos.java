public class CalculadoraMedicamentos {
    public int calcularDosesRestantes(int comprimidos, int dose) {
        return comprimidos/dose;
    }

    public boolean estoqueBaixo(int comprimidos, int limite) {
        return comrpimidos <= limite;
    }

    public int adicionarEstoque(int atual, int adicionar) {
        return atual + adicionar;
    }
}