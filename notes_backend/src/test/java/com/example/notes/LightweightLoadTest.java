package com.example.notes;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
class LightweightLoadTest {
  @Test
  void classLoads() {
    assertDoesNotThrow(() -> Class.forName("com.example.notes.NotesApplication"));
  }
}
