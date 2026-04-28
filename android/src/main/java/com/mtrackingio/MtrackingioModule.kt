package com.mtrackingio

import com.facebook.react.bridge.ReactApplicationContext

class MtrackingioModule(reactContext: ReactApplicationContext) :
  NativeMtrackingioSpec(reactContext) {

  override fun multiply(a: Double, b: Double): Double {
    return a * b
  }

  companion object {
    const val NAME = NativeMtrackingioSpec.NAME
  }
}
