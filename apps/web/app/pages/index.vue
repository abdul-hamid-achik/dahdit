<script setup lang="ts">
import { computed, ref } from 'vue'
import { encodeMorse, symbolsToCode, type MorseSymbol } from '@dahdit/morse-core'

const selected = ref('SOS')
const choices = ['SOS', 'CQ', 'DE', 'ET']

const symbols = computed(() => encodeMorse(selected.value))
const code = computed(() => symbolsToCode(symbols.value))

function classForSymbol(symbol: MorseSymbol) {
  if (symbol === 'dit') return 'dit'
  if (symbol === 'dah') return 'dah'
  return 'gap'
}
</script>

<template>
  <main class="page">
    <header class="shell topbar">
      <a class="brand" href="/" aria-label="Dahdit home">
        <span class="brand-mark">.-</span>
        <span>Dahdit</span>
      </a>
      <nav class="nav" aria-label="Primary navigation">
        <a href="#trainer">Trainer</a>
        <a href="#dashboard">Dashboard</a>
        <a href="https://api.dahdit.dev/graphql">API</a>
      </nav>
      <a class="button secondary" href="#dashboard">View dashboard</a>
    </header>

    <section id="trainer" class="shell hero">
      <div>
        <h1>Dahdit</h1>
        <p class="hero-copy">
          A mobile-first Morse code trainer for listening, tapping, spaced repetition, and daily operator practice.
        </p>
        <div class="hero-actions">
          <a class="button" href="#dashboard">Open learner view</a>
          <a class="button secondary" href="http://localhost:4000/graphql">GraphQL endpoint</a>
        </div>
        <div class="metrics" aria-label="Product metrics">
          <div class="metric">
            <strong>20 WPM</strong>
            <span>audio timing target</span>
          </div>
          <div class="metric">
            <strong>5 ms</strong>
            <span>tone envelope</span>
          </div>
          <div class="metric">
            <strong>30</strong>
            <span>review cap per day</span>
          </div>
        </div>
      </div>

      <div class="trainer" aria-label="Morse trainer preview">
        <div class="trainer-head">
          <strong>Listen and type</strong>
          <span class="hearts">5 hearts</span>
        </div>
        <div class="trainer-body">
          <div class="wave" aria-label="Morse waveform">
            <span v-for="(symbol, index) in symbols" :key="index" :class="classForSymbol(symbol)" />
          </div>
          <p>{{ selected }} is {{ code }}</p>
          <div class="answer-grid">
            <button
              v-for="choice in choices"
              :key="choice"
              class="answer"
              :class="{ selected: selected === choice }"
              type="button"
              @click="selected = choice"
            >
              {{ choice }}
            </button>
          </div>
        </div>
      </div>
    </section>

    <section id="dashboard" class="shell dashboard">
      <aside class="panel">
        <h2>Today</h2>
        <div class="metric">
          <strong>120 XP</strong>
          <span>earned this week</span>
        </div>
        <div class="metric">
          <strong>7 days</strong>
          <span>current streak</span>
        </div>
        <div class="metric">
          <strong>12 cards</strong>
          <span>due for review</span>
        </div>
      </aside>

      <div class="panel">
        <h2>Skill Tree</h2>
        <div class="tree">
          <div class="lesson">First Signals</div>
          <div class="lesson">A N T E</div>
          <div class="lesson locked">Numbers</div>
          <div class="lesson locked">Q Codes</div>
          <div class="lesson locked">Copy Speed</div>
          <div class="lesson locked">Prosigns</div>
        </div>

        <h3 style="margin-top: 28px">Leaderboard</h3>
        <div class="leaderboard-row">
          <strong>#1</strong>
          <span>abdul</span>
          <span>1480 XP</span>
        </div>
        <div class="leaderboard-row">
          <strong>#2</strong>
          <span>operator7</span>
          <span>1320 XP</span>
        </div>
        <div class="leaderboard-row">
          <strong>#3</strong>
          <span>netcontrol</span>
          <span>1110 XP</span>
        </div>
      </div>
    </section>
  </main>
</template>
