import React     from "react"
import MUI       from "material-ui"
import Intervals from "../../../model/trading/intervals"
import Theme     from "../../theme"

const DropDownMenu = MUI.DropDownMenu;

const items = Intervals.all().map(
  (item) => { return { id: item.id, text:item.name }; } );

export default class IntervalSelector extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      selectedIndex: 0
    };
  }

  componentWillMount() {
    const selectedIndex = this.getSelectedIndex(this.preferences().chartInterval);
    this.setState({selectedIndex:selectedIndex});
  }

  render() {
    return (
      <DropDownMenu
        className="interval-selector"
        menuItems={items}
        selectedIndex={this.state.selectedIndex}
        style={{width:Theme.chart.intervalSelector.width}}
        labelStyle={
          Object.assign({
            padding: "0 0 0 16px",
            color: Theme.getPalette().textColorLight
          }, Theme.chart.selector, this.props.labelStyle)
        }
        iconStyle={{right:"8px"}}
        underlineStyle={{margin: "0px"}}
        autoWidth={false}
        zDepth={5}
        onChange={this.onChange.bind(this)}/>
    );
  }

  onChange(e, selectedIndex, menuItem) {
    this.preferences().chartInterval = items[selectedIndex].id;
    this.setState({selectedIndex: selectedIndex});
  }

  getSelectedIndex(intervalId) {
    const index = items.findIndex((item)=>item.id === intervalId);
    return index === -1 ? 0 : index;
  }

  preferences() {
    return this.props.model.preferences;
  }
}

IntervalSelector.propTypes = {
  model: React.PropTypes.object.isRequired,
  labelStyle: React.PropTypes.object
};
IntervalSelector.defaultProps = {
  labelStyle: {}
};
