
import React from 'react';
import {
  NativeModules,
  requireNativeComponent,
  StyleSheet,
  View,
} from 'react-native';

const { func, number, string, bool, oneOf } = React.PropTypes;

const {func, number, string} = React.PropTypes;
const SketchManager = NativeModules.RNSketchManager || {};
const styles = StyleSheet.create({
  base: {
    flex: 1,
    height: 200,
  },
});

export default class Sketch extends React.Component {
  static propTypes = {
    onChange: func,
    onReset: func,
    clearButtonHidden: bool,
    onClearPlaceholder: func,
    strokeColor: string,
    strokeThickness: number,
    style: View.propTypes.style,
    imageType: oneOf(['jpg', 'png'])
  };

  static defaultProps = {
    onChange: () => {},
    onReset: () => {},
    clearButtonHidden: false,
    strokeColor: '#000000',
    strokeThickness: 1,
    style: null,
    imageType: 'jpg'
  };


  constructor(props) {
    super(props);
    this.onReset = this.onReset.bind(this);
    this.onUpdate = this.onUpdate.bind(this);
  }

  onReset() {
    this.props.onUpdate(null);
    this.props.onReset();
  }

  onUpdate(e) {
    if (e.nativeEvent.image) {
      this.props.onUpdate(`${BASE_64_CODE}${e.nativeEvent.image}`);
    } else {
      this.onReset();
    }
  }

  saveImage(image) {
    if (typeof image !== 'string') {
      return Promise.reject('You need to provide a valid base64 encoded image.');
    }

    return SketchManager.saveImage(src, this.props.imageType);
  }

  clear() {
    return SketchManager.clear();
  }

  render() {
    return (
      <RNSketch
        {...this.props}
        onChange={this.onUpdate}
        style={[styles.base, this.props.style]}
      />
    );
  }

}

const RNSketch = requireNativeComponent('RNSketch', Sketch);
